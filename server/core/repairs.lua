function MZMP.GetRepairItemName(kind)
    if kind == 'basic' then return Config.RepairItems.basic end
    if kind == 'advanced' then return Config.RepairItems.advanced end
    if kind == 'tire' then return Config.RepairItems.tire end
    if kind == 'cleaning' then return Config.RepairItems.cleaning end
    return nil
end

function MZMP.BeginRepairItemUse(src, kind, netId)
    if kind == 'toolbox' then
        return { ok = true }
    end

    local itemName = MZMP.GetRepairItemName(kind)
    if not itemName then
        return { ok = false, message = 'Item inválido.' }
    end

    if MZMP.Store.PendingRepairUses[src] then
        return { ok = false, message = 'Você já está usando um item de reparo.' }
    end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return { ok = false, message = 'Jogador inválido.' }
    end

    local vehicle = MZMP.GetVehicleEntity(netId)
    if vehicle == 0 then
        return { ok = false, message = 'Veículo inválido.' }
    end

    local playerCoords = MZMP.GetPlayerCoords(src)
    local vehicleCoords = GetEntityCoords(vehicle)
    local maxDistance = tonumber(Config.RepairItems.maxUseDistance) or 5.0

    if not playerCoords or #(playerCoords - vehicleCoords) > maxDistance then
        return { ok = false, message = 'Você está longe demais do veículo.' }
    end

    local ok = exports['qb-inventory']:RemoveItem(src, itemName, 1, false, 'mz_mechanicpanel:beginRepairItemUse')
    if not ok then
        return { ok = false, message = 'Você não possui o item necessário.' }
    end

    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')

    MZMP.Store.PendingRepairUses[src] = {
        kind = kind,
        itemName = itemName,
        startedAt = os.time(),
    }

    return { ok = true }
end

function MZMP.CancelRepairItemUse(src, kind)
    local pending = MZMP.Store.PendingRepairUses[src]
    if not pending or pending.kind ~= kind then return end

    if Config.RepairItems.refundOnCancel then
        exports['qb-inventory']:AddItem(src, pending.itemName, 1, false, false, 'mz_mechanicpanel:cancelRepairItemUse')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[pending.itemName], 'add')
    end

    MZMP.Store.PendingRepairUses[src] = nil
end

function MZMP.ConfirmRepairItemUse(src, kind)
    local pending = MZMP.Store.PendingRepairUses[src]
    if not pending or pending.kind ~= kind then return end

    local mechanicCitizenid = select(1, MZMP.GetMechanicIdentity(src))
    local ped = GetPlayerPed(src)
    local coords = ped ~= 0 and GetEntityCoords(ped) or nil

    MZMP.LogServiceAction({
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

    MZMP.Store.PendingRepairUses[src] = nil
end

function MZMP.ConsumeRepairItem(src, kind)
    local itemName = MZMP.GetRepairItemName(kind)
    if not itemName then return end
    if MZMP.Store.PendingRepairUses[src] then return end

    local ok = exports['qb-inventory']:RemoveItem(src, itemName, 1, false, 'mz_mechanicpanel:consumeRepairItem')
    if ok then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
    end
end

function MZMP.RegisterRepairItems()
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
end

function MZMP.StartRepairTimeoutThread()
    CreateThread(function()
        while true do
            Wait(30000)
            local now = os.time()
            local timeout = tonumber(Config.RepairItems.reserveTimeoutSeconds) or 120

            for src, pending in pairs(MZMP.Store.PendingRepairUses) do
                if now - (pending.startedAt or now) >= timeout then
                    if Config.RepairItems.refundOnCancel and pending.itemName then
                        exports['qb-inventory']:AddItem(src, pending.itemName, 1, false, false, 'mz_mechanicpanel:repairReserveTimeout')
                        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[pending.itemName], 'add')
                    end
                    MZMP.Store.PendingRepairUses[src] = nil
                end
            end
        end
    end)
end
