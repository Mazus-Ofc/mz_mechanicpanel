
local QBCore = exports['qb-core']:GetCoreObject()

local Sessions = {}
local PendingApprovals = {}
local PendingRepairUses = {}

local STATE_TO_PROP_KEYS = {
    engine = { 'modEngine' },
    brakes = { 'modBrakes' },
    transmission = { 'modTransmission' },
    suspension = { 'modSuspension' },
    armor = { 'modArmor' },
    turbo = { 'modTurbo' },

    paint_primary = { 'color1', 'customPrimaryColor' },
    paint_secondary = { 'color2', 'customSecondaryColor' },
    pearlescent = { 'pearlescentColor' },
    wheel_color = { 'wheelColor' },
    livery = { 'modLivery', 'livery' },

    wheel_type = { 'wheels' },
    wheels = { 'modFrontWheels', 'modBackWheels' },
    custom_tires = { 'modCustomTiresF', 'modCustomTiresR' },
    bulletproof_tires = { 'modBulletproofTires' },
    tire_smoke = { 'modSmokeEnabled', 'tyreSmokeColor' },

    tint = { 'windowTint' },
    xenon = { 'modXenon', 'xenonColor' },
    neon = { 'neonEnabled', 'neonColor' },
    plate = { 'plateIndex' },

    spoiler = { 'modSpoilers' },
    front_bumper = { 'modFrontBumper' },
    rear_bumper = { 'modRearBumper' },
    side_skirt = { 'modSideSkirt' },
    exhaust = { 'modExhaust' },
    frame = { 'modFrame' },
    grille = { 'modGrille' },
    hood = { 'modHood' },
    left_fender = { 'modFender' },
    right_fender = { 'modRightFender' },
    roof = { 'modRoof' },
    plate_holder = { 'modPlateHolder' },
    trim_design = { 'modTrimA' },
    ornaments = { 'modOrnaments' },
    dashboard = { 'modDashboard' },
    dial = { 'modDial' },
    door_speaker = { 'modDoorSpeaker' },
    seats = { 'modSeats' },
    steering_wheel = { 'modSteeringWheel' },
    shifter = { 'modShifterLeavers' },
    plaques = { 'modAPlate' },
    speakers = { 'modSpeakers' },
    trunk = { 'modTrunk' },
    hydraulics = { 'modHydraulics' },
    engine_block = { 'modEngineBlock' },
    air_filter = { 'modAirFilter' },
    struts = { 'modStruts' },
    arch_cover = { 'modArchCover' },
    aerials = { 'modAerials' },
    trim = { 'modTrimB' },
    tank = { 'modTank' },
    windows = { 'modWindows' },

    extras = { 'extras' },
    service_engine = { 'engineHealth' },
    service_body = { 'bodyHealth' },
    service_clean = { 'dirtLevel' },
    service_full = { 'engineHealth', 'bodyHealth', 'tankHealth', 'dirtLevel' },
}

local function dbg(...)
    if Config.Debug then
        print('^5[mz_mechanicpanel]^7', ...)
    end
end

local function trim(str)
    return (str and str:gsub('^%s*(.-)%s*$', '%1')) or ''
end

local function deepCopy(value)
    if type(value) ~= 'table' then return value end
    local copied = {}
    for k, v in pairs(value) do
        copied[k] = deepCopy(v)
    end
    return copied
end

local function decodeJson(value)
    if type(value) == 'table' then
        return deepCopy(value)
    end

    if type(value) ~= 'string' or value == '' then
        return nil
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return nil
end

local function serializeState(state)
    return json.encode(state or {})
end

local function isAdmin(src)
    return QBCore.Functions.HasPermission(src, Config.Access.adminGroups)
end

local function getPlayersList()
    if QBCore.Functions.GetPlayers then
        return QBCore.Functions.GetPlayers()
    end
    return GetPlayers()
end

local function getPlayerByCitizen(citizenid)
    for _, src in ipairs(getPlayersList()) do
        local player = QBCore.Functions.GetPlayer(tonumber(src))
        if player and player.PlayerData.citizenid == citizenid then
            return tonumber(src), player
        end
    end
end

local function getPlayerByPlateOwner(plate)
    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not row or not row.citizenid then return nil, nil, nil end

    local src, player = getPlayerByCitizen(row.citizenid)
    return src, player, row.citizenid
end

local function findClosestDriverPayer(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return nil, nil, nil end

    local ped = GetPedInVehicleSeat(vehicle, -1)
    if ped == 0 then return nil, nil, nil end

    local ownerSrc = NetworkGetEntityOwner(ped)
    if not ownerSrc then return nil, nil, nil end

    local player = QBCore.Functions.GetPlayer(ownerSrc)
    if not player then return nil, nil, nil end

    return ownerSrc, player, player.PlayerData.citizenid
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function getVehicleEntity(netId)
    local entity = NetworkGetEntityFromNetworkId(netId or 0)
    if entity == 0 or not DoesEntityExist(entity) then return 0 end
    return entity
end

local function getVehicleCoords(netId)
    local entity = getVehicleEntity(netId)
    if entity == 0 then return nil end
    return GetEntityCoords(entity)
end

local function getVehiclePlateByNetId(netId)
    local entity = getVehicleEntity(netId)
    if entity == 0 then return '' end
    return trim(GetVehicleNumberPlateText(entity))
end

local function canUsePanel(src, bay)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return false, 'Jogador inválido.'
    end

    if isAdmin(src) then
        return true
    end

    local job = player.PlayerData.job or {}
    local jobName = job.name

    if Config.Access.requireJobTypeMechanic and job.type ~= 'mechanic' then
        return false, 'Você não é mecânico.'
    end

    local allowed = false
    if bay.strictShopJob then
        allowed = (jobName == bay.shop)
    else
        allowed = Config.Access.allowedJobs[jobName] == true or job.type == 'mechanic'
    end

    if not allowed then
        return false, 'Você não tem acesso a esta oficina.'
    end

    return true
end

local function plateHasSession(plate)
    for sessionId, data in pairs(Sessions) do
        if data.plate == plate then
            return sessionId, data
        end
    end
end

local function releaseSessionBySource(src)
    PendingRepairUses[src] = nil

    for sessionId, data in pairs(Sessions) do
        if data.mechanicSrc == src or data.ownerSrc == src then
            Sessions[sessionId] = nil
        end
    end

    for requestId, req in pairs(PendingApprovals) do
        if req.mechanicSrc == src or req.ownerSrc == src then
            PendingApprovals[requestId] = nil
        end
    end
end

local function isVehicleInBay(netId, bay)
    local coords = getVehicleCoords(netId)
    if not coords then return false end

    local point = vec3(bay.vehiclePoint.x, bay.vehiclePoint.y, bay.vehiclePoint.z)
    return #(coords - point) <= (bay.vehicleDistance or Config.Panel.vehicleDistance)
end

local function validateSession(session, opts)
    opts = opts or {}

    local bay = Config.Bays[session.bayId]
    if not bay then
        return false, 'Baia não encontrada.'
    end

    local vehicle = getVehicleEntity(session.netId)
    if vehicle == 0 then
        return false, 'Veículo não encontrado.'
    end

    if Config.Security.requirePlateMatchOnSave then
        local serverPlate = getVehiclePlateByNetId(session.netId)
        if serverPlate == '' or serverPlate ~= trim(session.plate) then
            return false, 'A placa do veículo não confere mais com a sessão.'
        end
    end

    if not isVehicleInBay(session.netId, bay) then
        return false, 'O veículo saiu da baia.'
    end

    if not isAdmin(session.mechanicSrc) then
        local mechanicCoords = getPlayerCoords(session.mechanicSrc)
        if not mechanicCoords or #(mechanicCoords - bay.marker) > ((bay.interactDistance or Config.Panel.interactDistance) + 2.5) then
            return false, 'O mecânico saiu da área da oficina.'
        end
    end

    if opts.requireOwnerNearby and session.ownerSrc and Config.Panel.requireOwnerNearby then
        local vehicleCoords = GetEntityCoords(vehicle)
        local ownerCoords = getPlayerCoords(session.ownerSrc)
        if not ownerCoords or #(vehicleCoords - ownerCoords) > Config.Panel.ownerPayDistance then
            return false, 'O proprietário precisa estar perto do veículo.'
        end
    end

    return true, nil, vehicle, bay
end

local function getMechanicIdentity(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil, ('ID %s'):format(src) end

    local citizenid = player.PlayerData.citizenid
    local charinfo = player.PlayerData.charinfo or {}
    local fullName = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):gsub('^%s*(.-)%s*$', '%1')

    if fullName == '' then
        fullName = ('ID %s'):format(src)
    end

    return citizenid, fullName
end

local function getRepairItemName(kind)
    if kind == 'basic' then return Config.RepairItems.basic end
    if kind == 'advanced' then return Config.RepairItems.advanced end
    if kind == 'tire' then return Config.RepairItems.tire end
    if kind == 'cleaning' then return Config.RepairItems.cleaning end
    return nil
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function sanitizeColorArray(value)
    local t = type(value) == 'table' and value or {}
    return {
        math.floor(clamp(t[1] or t.r or 255, 0, 255)),
        math.floor(clamp(t[2] or t.g or 255, 0, 255)),
        math.floor(clamp(t[3] or t.b or 255, 0, 255)),
    }
end

local function sanitizeNeonEnabled(value)
    local t = type(value) == 'table' and value or {}
    return {
        t[1] == true or t.left == true,
        t[2] == true or t.right == true,
        t[3] == true or t.front == true,
        t[4] == true or t.back == true,
    }
end

local function sanitizeExtras(value)
    local clean = {}
    if type(value) ~= 'table' then return clean end

    for extraId, enabled in pairs(value) do
        local key = tostring(tonumber(extraId) or extraId)
        clean[key] = enabled == true
    end

    return clean
end

local function sanitizePropValue(key, value)
    if key == 'engineHealth' or key == 'bodyHealth' or key == 'tankHealth' then
        return clamp(value, 0, 1000.0)
    end

    if key == 'dirtLevel' then
        return clamp(value, 0, 15.0)
    end

    if key == 'customPrimaryColor' or key == 'customSecondaryColor' or key == 'tyreSmokeColor' or key == 'neonColor' then
        return sanitizeColorArray(value)
    end

    if key == 'neonEnabled' then
        return sanitizeNeonEnabled(value)
    end

    if key == 'extras' then
        return sanitizeExtras(value)
    end

    if key == 'plateIndex' then
        return math.floor(clamp(value, 0, 5))
    end

    if key == 'windowTint' then
        return math.floor(clamp(value, -1, 6))
    end

    if key == 'xenonColor' then
        return math.floor(clamp(value, -1, 255))
    end

    if key == 'color1' or key == 'color2' or key == 'pearlescentColor' or key == 'wheelColor' or key == 'wheels' then
        return math.floor(clamp(value, -1, 255))
    end

    if key == 'modTurbo' or key == 'modXenon' or key == 'modBulletproofTires' or key == 'modSmokeEnabled' or key == 'modCustomTiresF' or key == 'modCustomTiresR' then
        return value == true
    end

    if key:sub(1, 3) == 'mod' then
        return math.floor(clamp(value, -1, 255))
    end

    return value
end

local function mergeProps(baseProps, incomingProps, propKeys)
    local result = deepCopy(baseProps or {})
    local incoming = type(incomingProps) == 'table' and incomingProps or {}

    for propKey in pairs(propKeys or {}) do
        if incoming[propKey] ~= nil then
            result[propKey] = sanitizePropValue(propKey, incoming[propKey])
        end
    end

    return result
end

local function buildTouchedPropKeys(originalState, currentState)
    local touched = {}

    originalState = originalState or {}
    currentState = currentState or {}

    for stateKey, propList in pairs(STATE_TO_PROP_KEYS) do
        local originalValue = originalState[stateKey]
        local currentValue = currentState[stateKey]

        if MechanicShared.IsDifferent(originalValue, currentValue) then
            for _, propKey in ipairs(propList) do
                touched[propKey] = true
            end
        end
    end

    return touched
end

local function normalizeOriginalProps(props)
    local allowed = {}
    for _, propList in pairs(STATE_TO_PROP_KEYS) do
        for _, propKey in ipairs(propList) do
            allowed[propKey] = true
        end
    end

    allowed.engineHealth = true
    allowed.bodyHealth = true
    allowed.tankHealth = true
    allowed.dirtLevel = true

    return mergeProps({}, props or {}, allowed)
end

local function buildFinalProps(session, clientProps, existingDbProps)
    local baseProps = mergeProps(existingDbProps or {}, session.originalProps or {}, buildTouchedPropKeys(session.originalState, session.currentState))
    local touchedKeys = buildTouchedPropKeys(session.originalState, session.currentState)
    local finalProps = mergeProps(baseProps, clientProps or {}, touchedKeys)

    local currentState = session.currentState or {}

    if currentState.service_full then
        finalProps.engineHealth = 1000.0
        finalProps.bodyHealth = 1000.0
        finalProps.tankHealth = 1000.0
        finalProps.dirtLevel = 0.0
    else
        if currentState.service_engine then
            finalProps.engineHealth = 1000.0
        end

        if currentState.service_body then
            finalProps.bodyHealth = 1000.0
        end

        if currentState.service_clean then
            finalProps.dirtLevel = 0.0
        end
    end

    return finalProps
end

local function logServiceAction(payload)
    MySQL.insert.await([[
        INSERT INTO mechanic_service_logs (session_id, bay_id, plate, owner_citizenid, mechanic_citizenid, action, value, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.sessionId,
        payload.bayId,
        payload.plate,
        payload.ownerCitizenid,
        payload.mechanicCitizenid,
        payload.action,
        payload.value or 0,
        serializeState(payload.metadata or {})
    })
end

QBCore.Functions.CreateCallback('mz_mechanicpanel:server:requestOpen', function(source, cb, bayId, plate, netId)
    local bay = Config.Bays[bayId]
    if not bay then
        return cb({ ok = false, message = 'Baia inválida.' })
    end

    local allowed, reason = canUsePanel(source, bay)
    if not allowed then
        return cb({ ok = false, message = reason })
    end

    plate = trim(plate)
    if plate == '' then
        return cb({ ok = false, message = 'Placa inválida.' })
    end

    local vehicleCoords = getVehicleCoords(netId)
    local playerCoords = getPlayerCoords(source)
    if not vehicleCoords or not playerCoords then
        return cb({ ok = false, message = 'Veículo não encontrado.' })
    end

    if not isVehicleInBay(netId, bay) then
        return cb({ ok = false, message = 'O veículo não está posicionado na baia.' })
    end

    if #(playerCoords - bay.marker) > ((bay.interactDistance or Config.Panel.interactDistance) + 1.5) then
        return cb({ ok = false, message = 'Você não está na área do painel.' })
    end

    local existingSessionId = plateHasSession(plate)
    if existingSessionId then
        return cb({ ok = false, message = 'Este veículo já está sendo editado.' })
    end

    local ownerSrc, ownerPlayer = getPlayerByPlateOwner(plate)
    local ownerLabel = ownerPlayer and ownerPlayer.PlayerData.charinfo and ((ownerPlayer.PlayerData.charinfo.firstname or '') .. ' ' .. (ownerPlayer.PlayerData.charinfo.lastname or '')) or 'Cliente'

    local sessionId = ('%s:%s:%s'):format(source, plate, math.random(1000, 9999))
    Sessions[sessionId] = {
        sessionId = sessionId,
        mechanicSrc = source,
        ownerSrc = ownerSrc,
        netId = netId,
        bayId = bayId,
        plate = plate,
        startedAt = os.time(),
        shopLabel = bay.label,
        bypassPayment = isAdmin(source) and Config.Panel.allowAdminBypassPayment,
    }

    cb({ ok = true, sessionId = sessionId, ownerLabel = ownerLabel })
end)

RegisterNetEvent('mz_mechanicpanel:server:closeSession', function(sessionId)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.mechanicSrc ~= src then return end
    Sessions[sessionId] = nil
end)

RegisterNetEvent('mz_mechanicpanel:server:submitOrder', function(sessionId, originalState, currentState, originalProps)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.mechanicSrc ~= src then return end

    if Config.Security.revalidateVehicleOnSubmit then
        local ok, message = validateSession(session)
        if not ok then
            return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = message })
        end
    end

    local bay = Config.Bays[session.bayId]
    if not bay then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Baia não encontrada.' })
    end

    local orderState = currentState or {}
    originalState = originalState or {}
    local quote = MechanicShared.BuildQuote(originalState, orderState, bay.laborMultiplier or 1.0)

    if quote.total <= 0 or not quote.lines or #quote.lines <= 0 then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Nenhuma alteração foi selecionada.' })
    end

    session.originalState = originalState
    session.currentState = orderState
    session.originalProps = normalizeOriginalProps(originalProps)
    session.quote = quote

    if session.bypassPayment then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'approved', bypass = true })
    end

    local ownerSrc, ownerPlayer, citizenid = getPlayerByPlateOwner(session.plate)
    if not ownerSrc and Config.Panel.allowNonOwnedVehiclePaymentByDriver then
        ownerSrc, ownerPlayer, citizenid = findClosestDriverPayer(session.netId)
    end

    if not ownerSrc or not ownerPlayer then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Proprietário do veículo não está disponível para aprovar.' })
    end

    local vehicleCoords = getVehicleCoords(session.netId)
    local ownerCoords = getPlayerCoords(ownerSrc)
    if Config.Panel.requireOwnerNearby and vehicleCoords and ownerCoords then
        if #(vehicleCoords - ownerCoords) > Config.Panel.ownerPayDistance then
            return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'O proprietário precisa estar perto do veículo.' })
        end
    end

    session.ownerSrc = ownerSrc
    session.ownerCitizenid = citizenid

    local mechanicCitizenid, mechanicName = getMechanicIdentity(src)
    local requestId = ('req:%s:%s'):format(sessionId, math.random(1000, 9999))

    PendingApprovals[requestId] = {
        requestId = requestId,
        sessionId = sessionId,
        mechanicSrc = src,
        ownerSrc = ownerSrc,
        total = quote.total,
        quote = quote,
        plate = session.plate,
        shopLabel = bay.label,
        mechanicName = mechanicName,
        mechanicCitizenid = mechanicCitizenid,
    }

    TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'awaiting_owner' })
    TriggerClientEvent('mz_mechanicpanel:client:ownerApprovalRequest', ownerSrc, {
        requestId = requestId,
        total = quote.total,
        subtotal = quote.subtotal,
        labor = quote.labor,
        lines = quote.lines,
        plate = session.plate,
        mechanicName = mechanicName,
        shopLabel = bay.label,
    })
end)

RegisterNetEvent('mz_mechanicpanel:server:ownerApproval', function(requestId, accepted)
    local src = source
    local req = PendingApprovals[requestId]
    if not req or req.ownerSrc ~= src then return end

    local session = Sessions[req.sessionId]
    if not session then
        PendingApprovals[requestId] = nil
        return TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
    end

    local ownerPlayer = QBCore.Functions.GetPlayer(src)
    if not ownerPlayer then return end

    if not accepted then
        PendingApprovals[requestId] = nil
        TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
        TriggerClientEvent('mz_mechanicpanel:client:orderState', req.mechanicSrc, { type = 'declined' })
        return
    end

    if Config.Security.revalidateVehicleOnApproval then
        local ok, message = validateSession(session, { requireOwnerNearby = true })
        if not ok then
            PendingApprovals[requestId] = nil
            TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
            return TriggerClientEvent('mz_mechanicpanel:client:orderState', req.mechanicSrc, { type = 'error', message = message })
        end
    end

    local bank = ownerPlayer.PlayerData.money.bank or 0
    local cash = ownerPlayer.PlayerData.money.cash or 0
    local total = req.total or 0
    local paidFrom = nil

    if bank >= total then
        ownerPlayer.Functions.RemoveMoney('bank', total, 'mechanicpanel-service')
        paidFrom = 'bank'
    elseif cash >= total then
        ownerPlayer.Functions.RemoveMoney('cash', total, 'mechanicpanel-service')
        paidFrom = 'cash'
    else
        PendingApprovals[requestId] = nil
        TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', req.mechanicSrc, { type = 'error', message = 'O proprietário não possui dinheiro suficiente.' })
    end

    PendingApprovals[requestId] = nil
    session.paid = true
    session.paidFrom = paidFrom
    session.total = total
    session.quote = req.quote

    TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
    TriggerClientEvent('mz_mechanicpanel:client:orderState', req.mechanicSrc, { type = 'approved' })
end)

RegisterNetEvent('mz_mechanicpanel:server:saveApprovedProps', function(sessionId, clientProps)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.mechanicSrc ~= src then return end

    if not session.bypassPayment and not session.paid then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Pagamento ainda não confirmado.' })
    end

    if Config.Security.revalidateVehicleOnSave then
        local ok, message = validateSession(session)
        if not ok then
            return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = message })
        end
    end

    local plate = trim(session.plate)
    local row = MySQL.single.await('SELECT citizenid, mods FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    local existingDbProps = row and decodeJson(row.mods) or {}
    local finalProps = buildFinalProps(session, clientProps or {}, existingDbProps)

    if row then
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {
            json.encode(finalProps),
            plate
        })
    end

    local mechanicCitizenid = select(1, getMechanicIdentity(src))

    MySQL.insert.await([[
        INSERT INTO mechanic_orders (
            session_id, bay_id, plate, owner_citizenid, mechanic_citizenid, shop_label,
            items_json, approved_state_json, original_props_json, final_props_json,
            subtotal, labor, total, status, paid_from, bypass_payment
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        session.sessionId,
        session.bayId,
        plate,
        row and row.citizenid or session.ownerCitizenid,
        mechanicCitizenid,
        session.shopLabel,
        serializeState(session.quote and session.quote.lines or {}),
        serializeState(session.currentState or {}),
        serializeState(session.originalProps or {}),
        serializeState(finalProps or {}),
        session.quote and session.quote.subtotal or 0,
        session.quote and session.quote.labor or 0,
        session.quote and session.quote.total or 0,
        'paid',
        session.paidFrom or 'bypass',
        session.bypassPayment and 1 or 0
    })

    logServiceAction({
        sessionId = session.sessionId,
        bayId = session.bayId,
        plate = plate,
        ownerCitizenid = row and row.citizenid or session.ownerCitizenid,
        mechanicCitizenid = mechanicCitizenid,
        action = 'service_completed',
        value = session.quote and session.quote.total or 0,
        metadata = {
            shop = session.shopLabel,
            lines = session.quote and session.quote.lines or {},
            paidFrom = session.paidFrom or 'bypass',
            approvedState = session.currentState or {},
        }
    })

    Sessions[sessionId] = nil
end)

QBCore.Functions.CreateCallback('mz_mechanicpanel:server:beginRepairItemUse', function(source, cb, kind, netId)
    if kind == 'toolbox' then
        return cb({ ok = true })
    end

    local itemName = getRepairItemName(kind)
    if not itemName then
        return cb({ ok = false, message = 'Item inválido.' })
    end

    if PendingRepairUses[source] then
        return cb({ ok = false, message = 'Você já está usando um item de reparo.' })
    end

    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return cb({ ok = false, message = 'Jogador inválido.' })
    end

    local vehicle = getVehicleEntity(netId)
    if vehicle == 0 then
        return cb({ ok = false, message = 'Veículo inválido.' })
    end

    local playerCoords = getPlayerCoords(source)
    local vehicleCoords = GetEntityCoords(vehicle)
    local maxDistance = tonumber(Config.RepairItems.maxUseDistance) or 5.0

    if not playerCoords or #(playerCoords - vehicleCoords) > maxDistance then
        return cb({ ok = false, message = 'Você está longe demais do veículo.' })
    end

    local ok = exports['qb-inventory']:RemoveItem(source, itemName, 1, false, 'mz_mechanicpanel:beginRepairItemUse')
    if not ok then
        return cb({ ok = false, message = 'Você não possui o item necessário.' })
    end

    TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove')

    PendingRepairUses[source] = {
        kind = kind,
        itemName = itemName,
        startedAt = os.time(),
    }

    cb({ ok = true })
end)

RegisterNetEvent('mz_mechanicpanel:server:cancelRepairItemUse', function(kind)
    local src = source
    local pending = PendingRepairUses[src]
    if not pending or pending.kind ~= kind then return end

    if Config.RepairItems.refundOnCancel then
        exports['qb-inventory']:AddItem(src, pending.itemName, 1, false, false, 'mz_mechanicpanel:cancelRepairItemUse')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[pending.itemName], 'add')
    end

    PendingRepairUses[src] = nil
end)

RegisterNetEvent('mz_mechanicpanel:server:confirmRepairItemUse', function(kind)
    local src = source
    local pending = PendingRepairUses[src]
    if not pending or pending.kind ~= kind then return end

    local mechanicCitizenid = select(1, getMechanicIdentity(src))
    local ped = GetPlayerPed(src)
    local coords = ped ~= 0 and GetEntityCoords(ped) or nil

    logServiceAction({
        sessionId = nil,
        bayId = nil,
        plate = nil,
        ownerCitizenid = nil,
        mechanicCitizenid = mechanicCitizenid,
        action = 'repair_item_' .. tostring(kind),
        value = 0,
        metadata = {
            coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil,
            item = pending.itemName,
        }
    })

    PendingRepairUses[src] = nil
end)

RegisterNetEvent('mz_mechanicpanel:server:consumeRepairItem', function(kind)
    local src = source
    if not getRepairItemName(kind) then return end
    if PendingRepairUses[src] then return end

    local ok = exports['qb-inventory']:RemoveItem(src, getRepairItemName(kind), 1, false, 'mz_mechanicpanel:consumeRepairItem')
    if ok then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[getRepairItemName(kind)], 'remove')
    end
end)

CreateThread(function()
    if EnsureMechanicPanelSchema then
        EnsureMechanicPanelSchema()
    end

    local items = {
        [Config.RepairItems.basic] = 'basic',
        [Config.RepairItems.advanced] = 'advanced',
        [Config.RepairItems.tire] = 'tire',
        [Config.RepairItems.cleaning] = 'cleaning',
        [Config.RepairItems.toolbox] = 'toolbox',
    }

    for itemName, kind in pairs(items) do
        QBCore.Functions.CreateUseableItem(itemName, function(source)
            TriggerClientEvent('mz_mechanicpanel:client:useRepairItem', source, kind)
        end)
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        local timeout = tonumber(Config.RepairItems.reserveTimeoutSeconds) or 120

        for src, pending in pairs(PendingRepairUses) do
            if now - (pending.startedAt or now) >= timeout then
                if Config.RepairItems.refundOnCancel and pending.itemName then
                    exports['qb-inventory']:AddItem(src, pending.itemName, 1, false, false, 'mz_mechanicpanel:repairReserveTimeout')
                    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[pending.itemName], 'add')
                end
                PendingRepairUses[src] = nil
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    releaseSessionBySource(source)
end)