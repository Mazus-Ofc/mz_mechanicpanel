function MZMP.LogServiceAction(payload)
    if not Config.Logging or Config.Logging.enabled == false then
        return nil
    end

    return MySQL.insert.await([[
        INSERT INTO mechanic_service_logs (
            order_id, session_id, bay_id, plate, vehicle_model, owner_citizenid, mechanic_citizenid,
            shop_label, action, status, value, metadata
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.orderId,
        payload.sessionId,
        payload.bayId,
        payload.plate,
        payload.vehicleModel,
        payload.ownerCitizenid,
        payload.mechanicCitizenid,
        payload.shopLabel,
        payload.action,
        payload.status,
        payload.value or 0,
        MZMP.SerializeState(payload.metadata or {})
    })
end
