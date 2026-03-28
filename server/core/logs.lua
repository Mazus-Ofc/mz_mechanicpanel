function MZMP.LogServiceAction(payload)
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
        MZMP.SerializeState(payload.metadata or {})
    })
end
