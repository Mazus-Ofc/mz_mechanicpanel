MZMP.Store = {
    Sessions = {},
    SessionsByPlate = {},
    PendingApprovals = {},
    PendingApprovalsBySession = {},
    PendingRepairUses = {},
}

function MZMP.GetSession(sessionId)
    return MZMP.Store.Sessions[sessionId]
end

function MZMP.SetSession(sessionId, session)
    MZMP.Store.Sessions[sessionId] = session
    if session and session.plate then
        MZMP.Store.SessionsByPlate[session.plate] = sessionId
    end
end

function MZMP.RemoveSession(sessionId)
    local session = MZMP.Store.Sessions[sessionId]
    if session and session.plate and MZMP.Store.SessionsByPlate[session.plate] == sessionId then
        MZMP.Store.SessionsByPlate[session.plate] = nil
    end
    MZMP.Store.Sessions[sessionId] = nil
    return session
end

function MZMP.GetSessionByPlate(plate)
    local sessionId = MZMP.Store.SessionsByPlate[plate]
    if not sessionId then return nil, nil end
    return sessionId, MZMP.Store.Sessions[sessionId]
end

function MZMP.SetPendingApproval(requestId, request)
    MZMP.Store.PendingApprovals[requestId] = request
    if request and request.sessionId then
        MZMP.Store.PendingApprovalsBySession[request.sessionId] = requestId
    end
end

function MZMP.GetPendingApproval(requestId)
    return MZMP.Store.PendingApprovals[requestId]
end

function MZMP.RemovePendingApproval(requestId)
    local request = MZMP.Store.PendingApprovals[requestId]
    if request and request.sessionId and MZMP.Store.PendingApprovalsBySession[request.sessionId] == requestId then
        MZMP.Store.PendingApprovalsBySession[request.sessionId] = nil
    end
    MZMP.Store.PendingApprovals[requestId] = nil
    return request
end

function MZMP.RemovePendingApprovalBySession(sessionId)
    local requestId = MZMP.Store.PendingApprovalsBySession[sessionId]
    if not requestId then return nil end
    return MZMP.RemovePendingApproval(requestId)
end
