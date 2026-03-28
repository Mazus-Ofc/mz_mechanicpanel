QBCore.Functions.CreateCallback('mz_mechanicpanel:server:requestOpen', function(source, cb, bayId, plate, netId)
    local ok, resultOrMessage = MZMP.CreateSession(source, bayId, plate, netId)
    if not ok then
        return cb({ ok = false, message = resultOrMessage })
    end

    cb({
        ok = true,
        sessionId = resultOrMessage.sessionId,
        ownerLabel = resultOrMessage.ownerLabel,
    })
end)

RegisterNetEvent('mz_mechanicpanel:server:closeSession', function(sessionId)
    MZMP.CloseSessionForMechanic(source, sessionId)
end)

RegisterNetEvent('mz_mechanicpanel:server:submitOrder', function(sessionId, originalState, currentState, originalProps)
    local src = source
    local ok, result = MZMP.SubmitOrder(src, sessionId, originalState, currentState, originalProps)

    if not ok then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = result })
    end

    TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = result.type, bypass = result.bypass })

    if result.ownerSrc and result.ownerPayload then
        TriggerClientEvent('mz_mechanicpanel:client:ownerApprovalRequest', result.ownerSrc, result.ownerPayload)
    end
end)

RegisterNetEvent('mz_mechanicpanel:server:ownerApproval', function(requestId, accepted)
    local src = source
    local ok, message, actions = MZMP.HandleOwnerApproval(src, requestId, accepted)

    if actions and actions.closeOwnerRequest then
        TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', src)
    end

    if actions and actions.mechanicSrc and actions.mechanicState then
        TriggerClientEvent('mz_mechanicpanel:client:orderState', actions.mechanicSrc, actions.mechanicState)
    elseif not ok and actions and actions.mechanicSrc then
        TriggerClientEvent('mz_mechanicpanel:client:orderState', actions.mechanicSrc, { type = 'error', message = message })
    end
end)

RegisterNetEvent('mz_mechanicpanel:server:saveApprovedProps', function(sessionId, clientProps)
    local src = source
    local ok, message = MZMP.SaveApprovedProps(src, sessionId, clientProps)
    if not ok then
        return TriggerClientEvent('mz_mechanicpanel:client:orderState', src, { type = 'error', message = message })
    end
end)

QBCore.Functions.CreateCallback('mz_mechanicpanel:server:beginRepairItemUse', function(source, cb, kind, netId)
    cb(MZMP.BeginRepairItemUse(source, kind, netId))
end)

RegisterNetEvent('mz_mechanicpanel:server:cancelRepairItemUse', function(kind)
    MZMP.CancelRepairItemUse(source, kind)
end)

RegisterNetEvent('mz_mechanicpanel:server:confirmRepairItemUse', function(kind)
    MZMP.ConfirmRepairItemUse(source, kind)
end)

RegisterNetEvent('mz_mechanicpanel:server:consumeRepairItem', function(kind)
    MZMP.ConsumeRepairItem(source, kind)
end)

CreateThread(function()
    if EnsureMechanicPanelSchema then
        EnsureMechanicPanelSchema()
    end

    MZMP.RegisterRepairItems()
end)

MZMP.StartRepairTimeoutThread()

AddEventHandler('playerDropped', function()
    MZMP.ReleaseSessionBySource(source)
end)
