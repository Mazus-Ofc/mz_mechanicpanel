function MZMP.ReleaseSessionBySource(src)
    MZMP.Store.PendingRepairUses[src] = nil

    local sessionsToRemove = {}
    for sessionId, data in pairs(MZMP.Store.Sessions) do
        if data.mechanicSrc == src or data.ownerSrc == src then
            sessionsToRemove[#sessionsToRemove + 1] = sessionId
        end
    end

    for _, sessionId in ipairs(sessionsToRemove) do
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

    local sessionId = ('%s:%s:%s'):format(src, plate, math.random(1000, 9999))
    local session = {
        sessionId = sessionId,
        mechanicSrc = src,
        ownerSrc = ownerSrc,
        netId = netId,
        bayId = bayId,
        plate = plate,
        startedAt = os.time(),
        shopLabel = bay.label,
        bypassPayment = MZMP.IsAdmin(src) and Config.Panel.allowAdminBypassPayment,
    }

    MZMP.SetSession(sessionId, session)

    return true, {
        sessionId = sessionId,
        ownerLabel = ownerLabel,
    }
end
