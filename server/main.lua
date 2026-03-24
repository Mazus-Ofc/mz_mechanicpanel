local QBCore = exports['qb-core']:GetCoreObject()

local Sessions = {}
local PendingApprovals = {}

local function dbg(...)
    if Config.Debug then
        print('^5[mz_mechanicpanel]^7', ...)
    end
end

local function trim(str)
    return (str and str:gsub('^%s*(.-)%s*$', '%1')) or ''
end

local function isAdmin(src)
    return QBCore.Functions.HasPermission(src, Config.Access.adminGroups)
end

local function canUsePanel(src, bay)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'Jogador inválido.' end
    if isAdmin(src) then return true end

    local job = Player.PlayerData.job or {}
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

local function getPlayersList()
    if QBCore.Functions.GetPlayers then
        return QBCore.Functions.GetPlayers()
    end
    return GetPlayers()
end

local function getPlayerByCitizen(citizenid)
    for _, src in ipairs(getPlayersList()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(src))
        if Player and Player.PlayerData.citizenid == citizenid then
            return tonumber(src), Player
        end
    end
end

local function getPlayerByPlateOwner(plate)
    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not row or not row.citizenid then return nil, nil, nil end
    local src, Player = getPlayerByCitizen(row.citizenid)
    return src, Player, row.citizenid
end

local function findClosestDriverPayer(plate, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 then return nil, nil, nil end
    local ped = GetPedInVehicleSeat(vehicle, -1)
    if ped == 0 then return nil, nil, nil end
    local ownerSrc = NetworkGetEntityOwner(ped)
    if not ownerSrc then return nil, nil, nil end
    local Player = QBCore.Functions.GetPlayer(ownerSrc)
    if not Player then return nil, nil, nil end
    return ownerSrc, Player, Player.PlayerData.citizenid
end

local function releaseSessionBySource(src)
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

local function plateHasSession(plate)
    for sessionId, data in pairs(Sessions) do
        if data.plate == plate then return sessionId, data end
    end
end

local function getVehicleCoords(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then return nil end
    return GetEntityCoords(entity)
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function serializeState(state)
    return json.encode(state or {})
end

QBCore.Functions.CreateCallback('mz_mechanicpanel:server:requestOpen', function(source, cb, bayId, plate, netId)
    local bay = Config.Bays[bayId]
    if not bay then return cb({ ok = false, message = 'Baia inválida.' }) end

    local allowed, reason = canUsePanel(source, bay)
    if not allowed then return cb({ ok = false, message = reason }) end

    plate = trim(plate)
    if plate == '' then return cb({ ok = false, message = 'Placa inválida.' }) end

    local vehicleCoords = getVehicleCoords(netId)
    local playerCoords = getPlayerCoords(source)
    if not vehicleCoords or not playerCoords then
        return cb({ ok = false, message = 'Veículo não encontrado.' })
    end

    if #(vehicleCoords - vec3(bay.vehiclePoint.x, bay.vehiclePoint.y, bay.vehiclePoint.z)) > (bay.vehicleDistance or Config.Panel.vehicleDistance) then
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
    local ownerLabel = ownerPlayer and ownerPlayer.PlayerData.charinfo and (ownerPlayer.PlayerData.charinfo.firstname .. ' ' .. ownerPlayer.PlayerData.charinfo.lastname) or 'Cliente'

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

RegisterNetEvent('mz_mechanicpanel:server:submitOrder', function(sessionId, originalState, currentState, clientQuote)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.mechanicSrc ~= src then return end

    local bay = Config.Bays[session.bayId]
    if not bay then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Baia não encontrada.' })
    end

    local orderState = currentState or {}
    originalState = originalState or {}
    local quote = MechanicShared.BuildQuote(originalState, orderState, bay.laborMultiplier or 1.0)
    if quote.total <= 0 then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Nenhuma alteração foi selecionada.' })
    end

    session.originalState = originalState
    session.currentState = orderState
    session.quote = quote

    if session.bypassPayment then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'approved', bypass = true })
    end

    local ownerSrc, ownerPlayer, citizenid = getPlayerByPlateOwner(session.plate)

    if not ownerSrc and Config.Panel.allowNonOwnedVehiclePaymentByDriver then
        ownerSrc, ownerPlayer, citizenid = findClosestDriverPayer(session.plate, session.netId)
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

    local mechanicPlayer = QBCore.Functions.GetPlayer(src)
    local mechanicName = mechanicPlayer and mechanicPlayer.PlayerData.charinfo and (mechanicPlayer.PlayerData.charinfo.firstname .. ' ' .. mechanicPlayer.PlayerData.charinfo.lastname) or ('ID ' .. tostring(src))

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

RegisterNetEvent('mz_mechanicpanel:server:saveApprovedProps', function(sessionId, props)
    local src = source
    local session = Sessions[sessionId]
    if not session or session.mechanicSrc ~= src then return end

    if not session.bypassPayment and not session.paid then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = 'Pagamento ainda não confirmado.' })
    end

    local plate = trim(session.plate)
    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })

    if row then
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(props), plate })
    end

    MySQL.insert.await([[
        INSERT INTO mechanic_orders (plate, owner_citizenid, mechanic_citizenid, shop_label, items_json, subtotal, labor, total, status, paid_from)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        plate,
        row and row.citizenid or session.ownerCitizenid,
        (QBCore.Functions.GetPlayer(src) and QBCore.Functions.GetPlayer(src).PlayerData.citizenid) or nil,
        session.shopLabel,
        serializeState(session.quote and session.quote.lines or {}),
        session.quote and session.quote.subtotal or 0,
        session.quote and session.quote.labor or 0,
        session.quote and session.quote.total or 0,
        'paid',
        session.paidFrom or 'bypass'
    })

    MySQL.insert.await([[
        INSERT INTO mechanic_service_logs (plate, owner_citizenid, mechanic_citizenid, action, value, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        plate,
        row and row.citizenid or session.ownerCitizenid,
        (QBCore.Functions.GetPlayer(src) and QBCore.Functions.GetPlayer(src).PlayerData.citizenid) or nil,
        'service_completed',
        session.quote and session.quote.total or 0,
        serializeState({
            shop = session.shopLabel,
            lines = session.quote and session.quote.lines or {},
            paidFrom = session.paidFrom or 'bypass'
        })
    })

    Sessions[sessionId] = nil
end)

RegisterNetEvent('mz_mechanicpanel:server:consumeRepairItem', function(kind)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemName = nil
    if kind == 'basic' then itemName = Config.RepairItems.basic end
    if kind == 'advanced' then itemName = Config.RepairItems.advanced end
    if kind == 'tire' then itemName = Config.RepairItems.tire end
    if kind == 'cleaning' then itemName = Config.RepairItems.cleaning end
    if kind == 'toolbox' then itemName = nil end

    if itemName then
        local ok = exports['qb-inventory']:RemoveItem(src, itemName, 1, false, 'mz_mechanicpanel:consumeRepairItem')
        if ok then
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
        end
    end
end)

CreateThread(function()
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

AddEventHandler('playerDropped', function()
    releaseSessionBySource(source)
end)
