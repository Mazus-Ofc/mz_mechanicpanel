local QBCore = exports['qb-core']:GetCoreObject()

local state = {
    panelOpen = false,
    sessionId = nil,
    bayId = nil,
    bayData = nil,
    vehicle = nil,
    vehicleNetId = nil,
    originalProps = nil,
    originalState = nil,
    currentState = nil,
    quote = nil,
    cam = nil,
    camData = nil,
    pendingOwnerRequest = nil,
}

local function dbg(...)
    if Config.Debug then
        print('^5[mz_mechanicpanel]^7', ...)
    end
end

local function trim(str)
    return (str and str:gsub('^%s*(.-)%s*$', '%1')) or ''
end

local function notify(msg, typ)
    QBCore.Functions.Notify(msg, typ or 'primary')
end

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function drawMarkerAt(vec)
    DrawMarker(Config.Panel.markerType, vec.x, vec.y, vec.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        Config.Panel.markerScale.x, Config.Panel.markerScale.y, Config.Panel.markerScale.z,
        Config.Panel.markerColor.r, Config.Panel.markerColor.g, Config.Panel.markerColor.b, Config.Panel.markerColor.a,
        false, false, 2, false, nil, nil, false)
end

local function hasControl(entity)
    if not DoesEntityExist(entity) then return false end
    local timeout = GetGameTimer() + 1500
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end
    return NetworkHasControlOfEntity(entity)
end

local function hexToRgb(hex)
    hex = (hex or ''):gsub('#', '')
    if #hex ~= 6 then return 255, 255, 255 end
    return tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255
end

local function rgbToHex(r, g, b)
    return string.format('#%02x%02x%02x', math.floor(r or 0), math.floor(g or 0), math.floor(b or 0))
end

local function getVehicleLabel(vehicle)
    local model = GetEntityModel(vehicle)
    local display = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(display)
    if label == 'NULL' then label = display end
    return label
end

local function normalizePercent(value, max)
    max = max or 1.0
    local p = 0
    if max > 0 then p = (value / max) * 100.0 end
    if p < 0 then p = 0 end
    if p > 100 then p = 100 end
    return math.floor(p + 0.5)
end

local function getVehicleStats(vehicle)
    return {
        speed = normalizePercent(GetVehicleEstimatedMaxSpeed(vehicle), 95.0),
        acceleration = normalizePercent(GetVehicleAcceleration(vehicle), 1.4),
        brakes = normalizePercent(GetVehicleMaxBraking(vehicle), 1.4),
        traction = normalizePercent(GetVehicleMaxTraction(vehicle), 4.0),
    }
end

local function getCurrentBay()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for bayId, bay in pairs(Config.Bays) do
        local dist = #(coords - bay.marker)
        if dist <= math.max(Config.Panel.interactDistance, bay.interactDistance or 0) + 6.0 then
            return bayId, bay, dist
        end
    end
end

local function getVehicleAtBay(bay)
    local point = bay.vehiclePoint
    local coords = vec3(point.x, point.y, point.z)
    local vehicles = GetGamePool('CVehicle')
    local nearest, nearestDist
    for _, veh in ipairs(vehicles) do
        local dist = #(GetEntityCoords(veh) - coords)
        if dist <= (bay.vehicleDistance or Config.Panel.vehicleDistance) then
            if not nearestDist or dist < nearestDist then
                nearestDist = dist
                nearest = veh
            end
        end
    end
    return nearest, nearestDist or 9999
end

local function hasAnyOccupant(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for seat = -1, seats - 2 do
        if GetPedInVehicleSeat(vehicle, seat) ~= 0 then
            return true
        end
    end
    return false
end

local function setFreeze(vehicle, stateValue)
    if DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, stateValue)
        SetVehicleDoorsLocked(vehicle, stateValue and 2 or 1)
    end
end

local function destroyCam()
    if state.cam and DoesCamExist(state.cam) then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(state.cam, false)
    end
    state.cam = nil
    state.camData = nil
end

local function buildCamData(vehicle)
    local bayCam = (state.bayData and state.bayData.camera) or Config.Camera.default
    local vehCoords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local side = bayCam.sideOffset or Config.Camera.default.sideOffset
    local worldPos = GetOffsetFromEntityInWorldCoords(vehicle, side.x, side.y, side.z)
    return {
        pos = worldPos,
        rot = bayCam.rot or Config.Camera.default.rot,
        fov = bayCam.fov or Config.Camera.default.fov,
        heading = heading,
        zoom = bayCam.fov or Config.Camera.default.fov,
        focus = vehCoords + vec3(0.0, 0.0, 0.55)
    }
end

local function createVehicleCam(vehicle)
    destroyCam()
    local data = buildCamData(vehicle)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, data.pos.x, data.pos.y, data.pos.z)
    PointCamAtCoord(cam, data.focus.x, data.focus.y, data.focus.z)
    SetCamFov(cam, data.zoom)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 400, true, true)
    state.cam = cam
    state.camData = data
end

local function updateCamLook()
    if not state.cam or not state.vehicle or not DoesEntityExist(state.vehicle) then return end
    local focus = GetEntityCoords(state.vehicle) + vec3(0.0, 0.0, 0.55)
    state.camData.focus = focus
    PointCamAtCoord(state.cam, focus.x, focus.y, focus.z)
    SetCamFov(state.cam, state.camData.zoom)
end

local function rotateCam(direction)
    if not state.camData or not state.vehicle then return end
    local offset = GetOffsetFromEntityGivenWorldCoords(state.vehicle, state.camData.pos.x, state.camData.pos.y, state.camData.pos.z)
    local angle = math.atan(offset.y, offset.x)
    angle = angle + (direction == 'left' and 0.12 or -0.12)
    local radius = math.sqrt((offset.x * offset.x) + (offset.y * offset.y))
    local z = offset.z
    local newPos = GetOffsetFromEntityInWorldCoords(state.vehicle, math.cos(angle) * radius, math.sin(angle) * radius, z)
    state.camData.pos = newPos
    SetCamCoord(state.cam, newPos.x, newPos.y, newPos.z)
    updateCamLook()
end

local function zoomCam(delta)
    if not state.camData then return end
    state.camData.zoom = math.max(Config.Camera.minFov, math.min(Config.Camera.maxFov, state.camData.zoom + delta))
    SetCamFov(state.cam, state.camData.zoom)
end

local function getBaseState(vehicle)
    local primary, secondary = GetVehicleColours(vehicle)
    local pearlescent, wheelColor = GetVehicleExtraColours(vehicle)
    local xenonEnabled = IsToggleModOn(vehicle, 22)
    local xenonIndex = GetVehicleXenonLightsColor(vehicle)
    local xr, xg, xb = GetVehicleXenonLightsCustomColor(vehicle)
    local sr, sg, sb = GetVehicleTyreSmokeColor(vehicle)
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local liveryCount = GetVehicleLiveryCount(vehicle)
    local liveryModCount = GetNumVehicleMods(vehicle, 48)

    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    local services = {
        service_engine = false,
        service_body = false,
        service_tires = false,
        service_clean = false,
        service_full = false,
    }

    return {
        engine = GetVehicleMod(vehicle, 11),
        brakes = GetVehicleMod(vehicle, 12),
        transmission = GetVehicleMod(vehicle, 13),
        suspension = GetVehicleMod(vehicle, 15),
        turbo = IsToggleModOn(vehicle, 18),
        armor = GetVehicleMod(vehicle, 16),

        paint_primary = { type = GetIsVehiclePrimaryColourCustom(vehicle) and 'custom' or 'preset', index = primary, hex = rgbToHex(GetVehicleCustomPrimaryColour(vehicle)) },
        paint_secondary = { type = GetIsVehicleSecondaryColourCustom(vehicle) and 'custom' or 'preset', index = secondary, hex = rgbToHex(GetVehicleCustomSecondaryColour(vehicle)) },
        pearlescent = pearlescent,
        wheel_color = wheelColor,
        livery = liveryModCount > 0 and { mode = 'mod', index = GetVehicleMod(vehicle, 48) } or { mode = 'native', index = liveryCount > 0 and GetVehicleLivery(vehicle) or -1 },

        wheel_type = GetVehicleWheelType(vehicle),
        wheels = GetVehicleMod(vehicle, 23),
        custom_tires = GetVehicleModVariation(vehicle, 23),
        bulletproof_tires = not GetVehicleTyresCanBurst(vehicle),
        tire_smoke = { enabled = IsToggleModOn(vehicle, 20), hex = rgbToHex(sr, sg, sb) },

        tint = GetVehicleWindowTint(vehicle),
        xenon = { enabled = xenonEnabled, preset = xenonIndex, custom = (xr or 0) > 0 or (xg or 0) > 0 or (xb or 0) > 0, hex = rgbToHex(xr or 255, xg or 255, xb or 255) },
        neon = {
            left = IsVehicleNeonLightEnabled(vehicle, 0),
            right = IsVehicleNeonLightEnabled(vehicle, 1),
            front = IsVehicleNeonLightEnabled(vehicle, 2),
            back = IsVehicleNeonLightEnabled(vehicle, 3),
            hex = rgbToHex(nr, ng, nb),
        },
        plate = GetVehicleNumberPlateTextIndex(vehicle),

        spoiler = GetVehicleMod(vehicle, 0),
        front_bumper = GetVehicleMod(vehicle, 1),
        rear_bumper = GetVehicleMod(vehicle, 2),
        side_skirt = GetVehicleMod(vehicle, 3),
        exhaust = GetVehicleMod(vehicle, 4),
        frame = GetVehicleMod(vehicle, 5),
        grille = GetVehicleMod(vehicle, 6),
        hood = GetVehicleMod(vehicle, 7),
        left_fender = GetVehicleMod(vehicle, 8),
        right_fender = GetVehicleMod(vehicle, 9),
        roof = GetVehicleMod(vehicle, 10),

        plate_holder = GetVehicleMod(vehicle, 25),
        trim_design = GetVehicleMod(vehicle, 27),
        ornaments = GetVehicleMod(vehicle, 28),
        dashboard = GetVehicleMod(vehicle, 29),
        dial = GetVehicleMod(vehicle, 30),
        door_speaker = GetVehicleMod(vehicle, 31),
        seats = GetVehicleMod(vehicle, 32),
        steering_wheel = GetVehicleMod(vehicle, 33),
        shifter = GetVehicleMod(vehicle, 34),
        plaques = GetVehicleMod(vehicle, 35),
        speakers = GetVehicleMod(vehicle, 36),
        trunk = GetVehicleMod(vehicle, 37),
        hydraulics = GetVehicleMod(vehicle, 38),
        engine_block = GetVehicleMod(vehicle, 39),
        air_filter = GetVehicleMod(vehicle, 40),
        struts = GetVehicleMod(vehicle, 41),
        arch_cover = GetVehicleMod(vehicle, 42),
        aerials = GetVehicleMod(vehicle, 43),
        trim = GetVehicleMod(vehicle, 44),
        tank = GetVehicleMod(vehicle, 45),
        windows = GetVehicleMod(vehicle, 46),

        extras = extras,
        service_engine = services.service_engine,
        service_body = services.service_body,
        service_tires = services.service_tires,
        service_clean = services.service_clean,
        service_full = services.service_full,
    }
end

local function cloneState(tbl)
    return json.decode(json.encode(tbl))
end

local function getOptionLabel(prefix, index)
    if index == -1 then return 'Stock' end
    return string.format('%s %s', prefix, index + 1)
end

local function buildSectionPayload(vehicle)
    local sections = {}
    SetVehicleModKit(vehicle, 0)
    for _, category in ipairs(MechanicShared.Categories) do
        local items = {}
        for key, section in pairs(MechanicShared.Sections) do
            if section.category == category.key then
                local entry = {
                    key = section.key,
                    label = section.label,
                    icon = section.icon,
                    description = section.description,
                    mode = section.mode,
                    options = {},
                }
                local include = false

                if section.mode == 'mod' then
                    local count = GetNumVehicleMods(vehicle, section.modType)
                    if count > 0 then
                        include = true
                        entry.options[#entry.options + 1] = { value = -1, label = 'Stock' }
                        for i = 0, count - 1 do
                            entry.options[#entry.options + 1] = { value = i, label = getOptionLabel(section.label, i) }
                        end
                    end
                elseif section.mode == 'toggleMod' then
                    include = true
                    entry.options = {
                        { value = false, label = 'Desativado' },
                        { value = true, label = 'Ativado' },
                    }
                elseif section.mode == 'paintPrimary' or section.mode == 'paintSecondary' then
                    include = true
                    for _, color in ipairs(Config.PaintPresets) do
                        entry.options[#entry.options + 1] = { value = { type = 'preset', index = color.index }, label = color.label, hex = color.hex }
                    end
                    entry.allowCustomColor = true
                elseif section.mode == 'pearlescent' or section.mode == 'wheelColor' then
                    include = true
                    for _, color in ipairs(Config.PaintPresets) do
                        entry.options[#entry.options + 1] = { value = color.index, label = color.label, hex = color.hex }
                    end
                elseif section.mode == 'livery' then
                    local count = GetNumVehicleMods(vehicle, 48)
                    if count > 0 then
                        include = true
                        entry.options[#entry.options + 1] = { value = { mode = 'mod', index = -1 }, label = 'Stock' }
                        for i = 0, count - 1 do
                            entry.options[#entry.options + 1] = { value = { mode = 'mod', index = i }, label = 'Livery ' .. (i + 1) }
                        end
                    else
                        local lCount = GetVehicleLiveryCount(vehicle)
                        if lCount and lCount > 0 then
                            include = true
                            entry.options[#entry.options + 1] = { value = { mode = 'native', index = -1 }, label = 'Sem Livery' }
                            for i = 0, lCount - 1 do
                                entry.options[#entry.options + 1] = { value = { mode = 'native', index = i }, label = 'Livery ' .. (i + 1) }
                            end
                        end
                    end
                elseif section.mode == 'wheelType' then
                    include = true
                    for _, wheelType in ipairs(Config.WheelTypes) do
                        entry.options[#entry.options + 1] = { value = wheelType.id, label = wheelType.label }
                    end
                elseif section.mode == 'frontWheels' then
                    local count = GetNumVehicleMods(vehicle, 23)
                    if count > 0 then
                        include = true
                        entry.options[#entry.options + 1] = { value = -1, label = 'Stock' }
                        for i = 0, count - 1 do
                            entry.options[#entry.options + 1] = { value = i, label = 'Roda ' .. (i + 1) }
                        end
                    end
                elseif section.mode == 'wheelVariation' or section.mode == 'bulletproofTires' then
                    include = true
                    entry.options = {
                        { value = false, label = 'Desativado' },
                        { value = true, label = 'Ativado' },
                    }
                elseif section.mode == 'tireSmoke' then
                    include = true
                    for _, color in ipairs(Config.NeonPresets) do
                        entry.options[#entry.options + 1] = { value = { enabled = true, hex = color.hex }, label = color.label, hex = color.hex }
                    end
                    entry.options[#entry.options + 1] = { value = { enabled = false, hex = '#ffffff' }, label = 'Desativado' }
                    entry.allowCustomColor = true
                elseif section.mode == 'tint' then
                    include = true
                    for _, tint in ipairs(Config.WindowTints) do
                        entry.options[#entry.options + 1] = { value = tint.id, label = tint.label }
                    end
                elseif section.mode == 'xenon' then
                    include = true
                    entry.options[#entry.options + 1] = { value = { enabled = false, preset = 255, custom = false, hex = '#ffffff' }, label = 'Desativado' }
                    for _, preset in ipairs(Config.XenonPresets) do
                        entry.options[#entry.options + 1] = { value = { enabled = true, preset = preset.id, custom = false, hex = preset.hex or '#ffffff' }, label = preset.label, hex = preset.hex }
                    end
                    entry.allowCustomColor = true
                elseif section.mode == 'neon' then
                    include = true
                    for _, color in ipairs(Config.NeonPresets) do
                        entry.options[#entry.options + 1] = { value = { left = true, right = true, front = true, back = true, hex = color.hex }, label = color.label, hex = color.hex }
                    end
                    entry.options[#entry.options + 1] = { value = { left = false, right = false, front = false, back = false, hex = '#ffffff' }, label = 'Desativado' }
                    entry.allowCustomColor = true
                elseif section.mode == 'plate' then
                    include = true
                    for _, plate in ipairs(Config.PlateIndexes) do
                        entry.options[#entry.options + 1] = { value = plate.id, label = plate.label }
                    end
                elseif section.mode == 'extras' then
                    local hasAny = false
                    for i = 0, 20 do
                        if DoesExtraExist(vehicle, i) then
                            hasAny = true
                            entry.options[#entry.options + 1] = { value = tostring(i), label = 'Extra ' .. i }
                        end
                    end
                    include = hasAny
                elseif section.mode == 'serviceToggle' then
                    include = true
                    entry.options = {
                        { value = false, label = 'Não incluir' },
                        { value = true, label = 'Adicionar ao orçamento' },
                    }
                end

                if include then
                    items[#items + 1] = entry
                end
            end
        end
        table.sort(items, function(a, b) return a.label < b.label end)
        if #items > 0 then
            sections[#sections + 1] = {
                key = category.key,
                label = category.label,
                icon = category.icon,
                items = items,
            }
        end
    end
    return sections
end

local function applyStateToVehicle(vehicle, currentState, originalState, sectionKey)
    if not DoesEntityExist(vehicle) then return end
    if not hasControl(vehicle) then return end
    SetVehicleModKit(vehicle, 0)

    local section = MechanicShared.GetSection(sectionKey)
    if not section then return end
    local value = currentState[sectionKey]

    if section.mode == 'mod' then
        SetVehicleMod(vehicle, section.modType, tonumber(value) or -1, false)
    elseif section.mode == 'toggleMod' then
        ToggleVehicleMod(vehicle, section.modType, value == true)
    elseif section.mode == 'paintPrimary' then
        if value.type == 'custom' then
            local r, g, b = hexToRgb(value.hex)
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        else
            ClearVehicleCustomPrimaryColour(vehicle)
            local _, secondary = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, tonumber(value.index) or 0, secondary)
        end
    elseif section.mode == 'paintSecondary' then
        if value.type == 'custom' then
            local r, g, b = hexToRgb(value.hex)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        else
            ClearVehicleCustomSecondaryColour(vehicle)
            local primary = select(1, GetVehicleColours(vehicle))
            SetVehicleColours(vehicle, primary, tonumber(value.index) or 0)
        end
    elseif section.mode == 'pearlescent' then
        local _, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, tonumber(value) or 0, wheelColor)
    elseif section.mode == 'wheelColor' then
        local pearlescent = select(1, GetVehicleExtraColours(vehicle))
        SetVehicleExtraColours(vehicle, pearlescent, tonumber(value) or 0)
    elseif section.mode == 'livery' then
        if value.mode == 'mod' and GetNumVehicleMods(vehicle, 48) > 0 then
            SetVehicleMod(vehicle, 48, tonumber(value.index) or -1, false)
        else
            SetVehicleLivery(vehicle, tonumber(value.index) or -1)
        end
    elseif section.mode == 'wheelType' then
        SetVehicleWheelType(vehicle, tonumber(value) or 0)
    elseif section.mode == 'frontWheels' then
        SetVehicleMod(vehicle, 23, tonumber(value) or -1, currentState.custom_tires == true)
    elseif section.mode == 'wheelVariation' then
        local currentWheel = tonumber(currentState.wheels) or GetVehicleMod(vehicle, 23)
        SetVehicleMod(vehicle, 23, currentWheel, value == true)
    elseif section.mode == 'bulletproofTires' then
        SetVehicleTyresCanBurst(vehicle, not (value == true))
    elseif section.mode == 'tireSmoke' then
        ToggleVehicleMod(vehicle, 20, value.enabled == true)
        if value.enabled then
            local r, g, b = hexToRgb(value.hex)
            SetVehicleTyreSmokeColor(vehicle, r, g, b)
        end
    elseif section.mode == 'tint' then
        SetVehicleWindowTint(vehicle, tonumber(value) or 0)
    elseif section.mode == 'xenon' then
        ToggleVehicleMod(vehicle, 22, value.enabled == true)
        if value.enabled then
            if value.custom then
                local r, g, b = hexToRgb(value.hex)
                SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
            else
                if value.preset == 255 then
                    SetVehicleXenonLightsColor(vehicle, 255)
                else
                    SetVehicleXenonLightsColor(vehicle, tonumber(value.preset) or 255)
                end
            end
        end
    elseif section.mode == 'neon' then
        local r, g, b = hexToRgb(value.hex)
        SetVehicleNeonLightEnabled(vehicle, 0, value.left == true)
        SetVehicleNeonLightEnabled(vehicle, 1, value.right == true)
        SetVehicleNeonLightEnabled(vehicle, 2, value.front == true)
        SetVehicleNeonLightEnabled(vehicle, 3, value.back == true)
        SetVehicleNeonLightsColour(vehicle, r, g, b)
    elseif section.mode == 'plate' then
        SetVehicleNumberPlateTextIndex(vehicle, tonumber(value) or 0)
    elseif section.mode == 'extras' then
        for extraId, enabled in pairs(value) do
            local ex = tonumber(extraId)
            if ex and DoesExtraExist(vehicle, ex) then
                SetVehicleExtra(vehicle, ex, enabled and 0 or 1)
            end
        end
    elseif section.mode == 'serviceToggle' then
        -- nada durante preview; serviço entra só na aprovação final.
    end
end

local function revertPreview()
    if state.vehicle and DoesEntityExist(state.vehicle) and state.originalProps then
        hasControl(state.vehicle)
        QBCore.Functions.SetVehicleProperties(state.vehicle, state.originalProps)
        SetVehicleEngineHealth(state.vehicle, state.originalProps.engineHealth or 1000.0)
        SetVehicleBodyHealth(state.vehicle, state.originalProps.bodyHealth or 1000.0)
        SetVehicleDirtLevel(state.vehicle, state.originalProps.dirtLevel or 0.0)
        if state.originalProps.tyreHealth then
            for i = 0, 7 do
                if state.originalProps.tyreHealth[i + 1] == 1000.0 then
                    SetVehicleTyreFixed(state.vehicle, i)
                end
            end
        end
    end
    state.currentState = state.originalState and cloneState(state.originalState) or nil
end

local function refreshQuote()
    if not state.originalState or not state.currentState then return end
    local laborMultiplier = (state.bayData and state.bayData.laborMultiplier) or 1.0
    state.quote = MechanicShared.BuildQuote(state.originalState, state.currentState, laborMultiplier)
end

local function sendUiUpdate()
    refreshQuote()
    SendNUIMessage({
        action = 'summary',
        quote = state.quote,
        currentState = state.currentState,
        stats = state.vehicle and DoesEntityExist(state.vehicle) and getVehicleStats(state.vehicle) or nil,
    })
end

local function closePanel(internalCancel)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closePanel' })
    destroyCam()
    if state.vehicle and DoesEntityExist(state.vehicle) and Config.Panel.lockVehicleWhileEditing then
        setFreeze(state.vehicle, false)
    end
    if internalCancel then
        revertPreview()
    end
    if state.sessionId then
        TriggerServerEvent('mz_mechanicpanel:server:closeSession', state.sessionId, internalCancel == true)
    end
    state.panelOpen = false
    state.sessionId = nil
    state.bayId = nil
    state.bayData = nil
    state.vehicle = nil
    state.vehicleNetId = nil
    state.originalProps = nil
    state.originalState = nil
    state.currentState = nil
    state.quote = nil
end

local function openPanel(sessionId, bayId, bayData, vehicle, ownerLabel)
    local plate = trim(QBCore.Functions.GetPlate(vehicle))
    state.panelOpen = true
    state.sessionId = sessionId
    state.bayId = bayId
    state.bayData = bayData
    state.vehicle = vehicle
    state.vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    state.originalProps = QBCore.Functions.GetVehicleProperties(vehicle)
    state.originalProps.engineHealth = GetVehicleEngineHealth(vehicle)
    state.originalProps.bodyHealth = GetVehicleBodyHealth(vehicle)
    state.originalProps.dirtLevel = GetVehicleDirtLevel(vehicle)
    state.originalState = getBaseState(vehicle)
    state.currentState = cloneState(state.originalState)
    refreshQuote()

    if Config.Panel.lockVehicleWhileEditing then
        setFreeze(vehicle, true)
    end

    createVehicleCam(vehicle)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openPanel',
        payload = {
            sessionId = sessionId,
            vehicleLabel = getVehicleLabel(vehicle),
            plate = plate,
            ownerLabel = ownerLabel or 'Cliente',
            stats = getVehicleStats(vehicle),
            categories = buildSectionPayload(vehicle),
            currentState = state.currentState,
            quote = state.quote,
            currency = Config.CurrencySymbol,
            shopLabel = bayData.label,
        }
    })
end

local function tryOpenPanel(bayId, bayData)
    if state.panelOpen then return end
    local vehicle = getVehicleAtBay(bayData)
    local distVehicle
    vehicle, distVehicle = getVehicleAtBay(bayData)
    if not vehicle or vehicle == 0 then
        return notify('Leve um veículo para a baia antes de abrir o painel.', 'error')
    end

    if Config.Panel.requireVehicleStopped and GetEntitySpeed(vehicle) > 0.1 then
        return notify('O veículo precisa estar parado.', 'error')
    end

    if Config.Panel.requireVehicleEmpty and hasAnyOccupant(vehicle) then
        return notify('O veículo precisa estar vazio para iniciar o serviço.', 'error')
    end

    local plate = trim(QBCore.Functions.GetPlate(vehicle))
    if plate == '' then return notify('Placa do veículo não encontrada.', 'error') end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    QBCore.Functions.TriggerCallback('mz_mechanicpanel:server:requestOpen', function(resp)
        if not resp or not resp.ok then
            return notify((resp and resp.message) or 'Não foi possível abrir o painel.', 'error')
        end
        openPanel(resp.sessionId, bayId, bayData, vehicle, resp.ownerLabel)
    end, bayId, plate, netId)
end

local function updateSectionValue(sectionKey, rawValue)
    if not state.panelOpen or not state.currentState or not state.vehicle then return end
    local section = MechanicShared.GetSection(sectionKey)
    if not section then return end

    if section.mode == 'extras' then
        local extras = state.currentState.extras or {}
        local key = tostring(rawValue)
        extras[key] = not extras[key]
        state.currentState.extras = extras
    elseif section.mode == 'paintPrimary' or section.mode == 'paintSecondary' then
        if rawValue.customHex then
            state.currentState[sectionKey] = { type = 'custom', hex = rawValue.customHex, index = -1 }
        else
            state.currentState[sectionKey] = rawValue
        end
    elseif section.mode == 'xenon' then
        if rawValue.customHex then
            state.currentState[sectionKey] = { enabled = true, preset = 255, custom = true, hex = rawValue.customHex }
        else
            state.currentState[sectionKey] = rawValue
        end
    elseif section.mode == 'serviceToggle' then
        local enabled = rawValue == true

        if sectionKey == 'service_full' then
            state.currentState.service_full = enabled
            if enabled then
                state.currentState.service_engine = false
                state.currentState.service_body = false
                state.currentState.service_tires = false
                state.currentState.service_clean = false
            end
        else
            state.currentState[sectionKey] = enabled
            if enabled and state.currentState.service_full then
                state.currentState.service_full = false
            end

            if state.currentState.service_engine and state.currentState.service_body and state.currentState.service_tires and state.currentState.service_clean then
                state.currentState.service_full = true
                state.currentState.service_engine = false
                state.currentState.service_body = false
                state.currentState.service_tires = false
                state.currentState.service_clean = false
            end
        end
    elseif section.mode == 'neon' then
        if rawValue.customHex then
            state.currentState[sectionKey] = { left = true, right = true, front = true, back = true, hex = rawValue.customHex }
        else
            state.currentState[sectionKey] = rawValue
        end
    elseif section.mode == 'tireSmoke' then
        if rawValue.customHex then
            state.currentState[sectionKey] = { enabled = true, hex = rawValue.customHex }
        else
            state.currentState[sectionKey] = rawValue
        end
    else
        state.currentState[sectionKey] = rawValue
    end

    applyStateToVehicle(state.vehicle, state.currentState, state.originalState, sectionKey)
    sendUiUpdate()
end

local function applyServiceActions(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if state.currentState.service_full then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        for i = 0, 7 do SetVehicleTyreFixed(vehicle, i) end
    else
        if state.currentState.service_engine then
            SetVehicleEngineHealth(vehicle, 1000.0)
        end
        if state.currentState.service_body then
            SetVehicleBodyHealth(vehicle, 1000.0)
            SetVehicleDeformationFixed(vehicle)
        end
        if state.currentState.service_tires then
            for i = 0, 7 do SetVehicleTyreFixed(vehicle, i) end
        end
    end
    if state.currentState.service_clean or state.currentState.service_full then
        SetVehicleDirtLevel(vehicle, 0.0)
    end
end

RegisterNUICallback('previewChange', function(data, cb)
    if not state.panelOpen then return cb({ ok = false }) end
    updateSectionValue(data.sectionKey, data.value)
    cb({
        ok = true,
        quote = state.quote,
        currentState = state.currentState,
        categories = buildSectionPayload(state.vehicle),
        stats = getVehicleStats(state.vehicle)
    })
end)

RegisterNUICallback('finishOrder', function(_, cb)
    if not state.panelOpen or not state.sessionId then
        return cb({ ok = false, message = 'Sessão inválida.' })
    end

    refreshQuote()

    TriggerServerEvent(
        'mz_mechanicpanel:server:submitOrder',
        state.sessionId,
        state.originalState,
        state.currentState,
        state.originalProps
    )

    cb({ ok = true })
end)

RegisterNUICallback('closePanel', function(_, cb)
    closePanel(true)
    cb({ ok = true })
end)

RegisterNUICallback('rotateCamera', function(data, cb)
    rotateCam(data.direction or 'left')
    cb({ ok = true })
end)

RegisterNUICallback('zoomCamera', function(data, cb)
    zoomCam(tonumber(data.delta) or 0)
    cb({ ok = true })
end)

RegisterNUICallback('ownerApproval', function(data, cb)
    TriggerServerEvent('mz_mechanicpanel:server:ownerApproval', data.requestId, data.accepted == true)
    cb({ ok = true })
end)

RegisterNetEvent('mz_mechanicpanel:client:orderState', function(payload)
    if not payload then return end
    if payload.type == 'awaiting_owner' then
        notify('Orçamento enviado para aprovação do proprietário.', 'primary')
        SendNUIMessage({ action = 'awaitingOwner' })
    elseif payload.type == 'declined' then
        notify('O proprietário recusou o orçamento.', 'error')
        closePanel(true)
    elseif payload.type == 'approved' then
    if state.vehicle and DoesEntityExist(state.vehicle) then
        applyServiceActions(state.vehicle)

        local props = QBCore.Functions.GetVehicleProperties(state.vehicle)
        props.engineHealth = GetVehicleEngineHealth(state.vehicle)
        props.bodyHealth = GetVehicleBodyHealth(state.vehicle)
        props.tankHealth = GetVehiclePetrolTankHealth(state.vehicle)
        props.dirtLevel = GetVehicleDirtLevel(state.vehicle)

        TriggerServerEvent('mz_mechanicpanel:server:saveApprovedProps', state.sessionId, props)
        notify('Serviço aprovado e salvo com sucesso.', 'success')
        closePanel(false)
    end
    elseif payload.type == 'error' then
        notify(payload.message or 'Erro no serviço.', 'error')
    end
end)

RegisterNetEvent('mz_mechanicpanel:client:ownerApprovalRequest', function(payload)
    state.pendingOwnerRequest = payload.requestId
    SendNUIMessage({ action = 'ownerApprovalRequest', payload = payload })
    notify('Você recebeu uma solicitação de serviço da oficina.', 'primary')
end)

RegisterNetEvent('mz_mechanicpanel:client:closeOwnerRequest', function()
    state.pendingOwnerRequest = nil
    SendNUIMessage({ action = 'closeOwnerRequest' })
end)


local function requestRepairItemUse(kind, vehicle, cb)
    if kind == 'toolbox' then
        return cb({ ok = true })
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    QBCore.Functions.TriggerCallback('mz_mechanicpanel:server:beginRepairItemUse', function(resp)
        cb(resp or { ok = false, message = 'Não foi possível validar o item.' })
    end, kind, netId)
end

local function confirmRepairItemUse(kind)
    if kind == 'toolbox' then return end
    TriggerServerEvent('mz_mechanicpanel:server:confirmRepairItemUse', kind)
end

local function cancelRepairItemUse(kind)
    if kind == 'toolbox' then return end
    TriggerServerEvent('mz_mechanicpanel:server:cancelRepairItemUse', kind)
end


RegisterNetEvent('mz_mechanicpanel:client:useRepairItem', function(kind)
    local vehicle, distance = QBCore.Functions.GetClosestVehicle()
    if vehicle == 0 or distance > (Config.RepairItems.maxUseDistance or 5.0) then
        return notify('Nenhum veículo próximo.', 'error')
    end

    if kind == 'toolbox' then
        local engine = math.floor(GetVehicleEngineHealth(vehicle) / 10)
        local body = math.floor(GetVehicleBodyHealth(vehicle) / 10)
        local dirt = math.floor(GetVehicleDirtLevel(vehicle) * 10)
        return notify(('Diagnóstico | Motor: %s%% | Lataria: %s%% | Sujeira: %s%%'):format(engine, body, dirt), 'primary')
    end

    requestRepairItemUse(kind, vehicle, function(resp)
        if not resp or not resp.ok then
            return notify((resp and resp.message) or 'Você não possui o item necessário.', 'error')
        end

        if kind == 'basic' then
            QBCore.Functions.Progressbar('mz_mech_basic_repair', 'Aplicando reparo básico...', 9000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                SetVehicleEngineHealth(vehicle, math.min(1000.0, GetVehicleEngineHealth(vehicle) + 180.0))
                SetVehicleBodyHealth(vehicle, math.min(1000.0, GetVehicleBodyHealth(vehicle) + 120.0))
                confirmRepairItemUse(kind)
                notify('Reparo básico concluído.', 'success')
            end, function()
                cancelRepairItemUse(kind)
                notify('Uso do item cancelado.', 'error')
            end)

        elseif kind == 'advanced' then
            QBCore.Functions.Progressbar('mz_mech_full_repair', 'Aplicando reparo avançado...', 11000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehiclePetrolTankHealth(vehicle, 1000.0)
                confirmRepairItemUse(kind)
                notify('Reparo avançado concluído.', 'success')
            end, function()
                cancelRepairItemUse(kind)
                notify('Uso do item cancelado.', 'error')
            end)

        elseif kind == 'tire' then
            QBCore.Functions.Progressbar('mz_mech_tire_repair', 'Reparando pneus...', 7000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                for i = 0, 7 do
                    SetVehicleTyreFixed(vehicle, i)
                end
                confirmRepairItemUse(kind)
                notify('Pneus reparados.', 'success')
            end, function()
                cancelRepairItemUse(kind)
                notify('Uso do item cancelado.', 'error')
            end)

        elseif kind == 'cleaning' then
            QBCore.Functions.Progressbar('mz_mech_clean', 'Limpando veículo...', 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                SetVehicleDirtLevel(vehicle, 0.0)
                confirmRepairItemUse(kind)
                notify('Veículo limpo.', 'success')
            end, function()
                cancelRepairItemUse(kind)
                notify('Uso do item cancelado.', 'error')
            end)
        end
    end)
end)

CreateThread(function()
    while true do
        local waitTime = 1000
        if not state.panelOpen then
            local bayId, bay, dist = getCurrentBay()
            if bayId and bay then
                waitTime = 0
                drawMarkerAt(bay.marker)
                if dist <= (bay.interactDistance or Config.Panel.interactDistance) + 0.2 then
                    helpText(('~INPUT_CONTEXT~ Abrir painel de mecânica\n~c~%s'):format(bay.label))
                    if IsControlJustReleased(0, Config.Panel.openKey) then
                        tryOpenPanel(bayId, bay)
                    end
                end
            end
        else
            waitTime = 0
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            updateCamLook()
            local ped = PlayerPedId()
            if state.bayData and #(GetEntityCoords(ped) - state.bayData.marker) > Config.Panel.closeDistanceTolerance then
                notify('Você se afastou demais da baia. Serviço cancelado.', 'error')
                closePanel(true)
            end
        end
        Wait(waitTime)
    end
end)

RegisterCommand(Config.Panel.command, function()
    local bayId, bay = getCurrentBay()
    if not bayId then return notify('Nenhuma baia de mecânica próxima.', 'error') end
    tryOpenPanel(bayId, bay)
end)

RegisterCommand(Config.Panel.cancelCommand, function()
    if state.panelOpen then
        closePanel(true)
    else
        notify('Nenhuma sessão de mecânica ativa.', 'error')
    end
end)
