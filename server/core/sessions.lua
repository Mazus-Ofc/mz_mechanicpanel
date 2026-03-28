function MZMP.ReleaseSessionBySource(src)
    MZMP.Store.PendingRepairUses[src] = nil

    local sessionsToRemove = {}
    for sessionId, data in pairs(MZMP.Store.Sessions) do
        if data.mechanicSrc == src or data.ownerSrc == src then
            sessionsToRemove[#sessionsToRemove + 1] = sessionId
        end
    end

    for _, sessionId in ipairs(sessionsToRemove) do
        local session = MZMP.GetSession(sessionId)
        if session and session.orderId then
            MZMP.UpdateOrderStatus(session, 'cancelled', {
                metadata = {
                    reason = 'player_dropped',
                    droppedSource = src,
                }
            })

            MZMP.LogServiceAction({
                orderId = session.orderId,
                sessionId = session.sessionId,
                bayId = session.bayId,
                plate = session.plate,
                vehicleModel = session.vehicleModel,
                ownerCitizenid = session.ownerCitizenid,
                mechanicCitizenid = session.mechanicCitizenid,
                shopLabel = session.shopLabel,
                action = 'session_cancelled',
                status = 'cancelled',
                value = session.quote and session.quote.total or 0,
                metadata = {
                    reason = 'player_dropped',
                    droppedSource = src,
                }
            })
        end

        MZMP.RemovePendingApprovalBySession(sessionId)
        MZMP.RemoveSession(sessionId)
    end

    local requestsToRemove = {}
    for requestId, req in pairs(MZMP.Store.PendingApprovals) do
        if req.mechanicSrc == src or req.ownerSrc == src then
            requestsToRemove[#requestsToRemove + 1] = requestId
        end
    end

    for _, requestId in ipairs(requestsToRemove) do
        MZMP.RemovePendingApproval(requestId)
    end
end

function MZMP.CloseSessionForMechanic(src, sessionId)
    local session = MZMP.GetSession(sessionId)
    if not session or session.mechanicSrc ~= src then
        return false
    end

    if session.orderId then
        MZMP.UpdateOrderStatus(session, 'cancelled', {
            metadata = {
                reason = 'mechanic_closed_panel',
            }
        })

        MZMP.LogServiceAction({
            orderId = session.orderId,
            sessionId = session.sessionId,
            bayId = session.bayId,
            plate = session.plate,
            vehicleModel = session.vehicleModel,
            ownerCitizenid = session.ownerCitizenid,
            mechanicCitizenid = session.mechanicCitizenid,
            shopLabel = session.shopLabel,
            action = 'session_cancelled',
            status = 'cancelled',
            value = session.quote and session.quote.total or 0,
            metadata = {
                reason = 'mechanic_closed_panel',
            }
        })
    end

    MZMP.RemovePendingApprovalBySession(sessionId)
    MZMP.RemoveSession(sessionId)
    return true
end

function MZMP.CreateSession(src, bayId, plate, netId)
    local bay = Config.Bays[bayId]
    if not bay then
        return false, 'Baia inválida.'
    end

    local allowed, reason = MZMP.CanUsePanel(src, bay)
    if not allowed then
        return false, reason
    end

    plate = MZMP.Trim(plate)
    if plate == '' then
        return false, 'Placa inválida.'
    end

    local vehicleCoords = MZMP.GetVehicleCoords(netId)
    local playerCoords = MZMP.GetPlayerCoords(src)
    if not vehicleCoords or not playerCoords then
        return false, 'Veículo não encontrado.'
    end

    if not MZMP.IsVehicleInBay(netId, bay) then
        return false, 'O veículo não está posicionado na baia.'
    end

    if #(playerCoords - bay.marker) > ((bay.interactDistance or Config.Panel.interactDistance) + 1.5) then
        return false, 'Você não está na área do painel.'
    end

    local existingSessionId = MZMP.GetSessionByPlate(plate)
    if existingSessionId then
        return false, 'Este veículo já está sendo editado.'
    end

    local ownerSrc, ownerPlayer = MZMP.GetPlayerByPlateOwner(plate)
    local ownerLabel = ownerPlayer and ownerPlayer.PlayerData.charinfo and ((ownerPlayer.PlayerData.charinfo.firstname or '') .. ' ' .. (ownerPlayer.PlayerData.charinfo.lastname or '')) or 'Cliente'
    local mechanicCitizenid = select(1, MZMP.GetMechanicIdentity(src))
    local _, vehicleModel = MZMP.GetVehicleModelData(netId)

    local sessionId = ('%s:%s:%s'):format(src, plate, math.random(1000, 9999))
    local session = {
        sessionId = sessionId,
        mechanicSrc = src,
        mechanicCitizenid = mechanicCitizenid,
        ownerSrc = ownerSrc,
        netId = netId,
        bayId = bayId,
        plate = plate,
        startedAt = os.time(),
        shopLabel = bay.label,
        vehicleModel = vehicleModel,
        bypassPayment = MZMP.IsAdmin(src) and Config.Panel.allowAdminBypassPayment,
    }

    MZMP.SetSession(sessionId, session)

    return true, {
        sessionId = sessionId,
        ownerLabel = ownerLabel,
    }
end
