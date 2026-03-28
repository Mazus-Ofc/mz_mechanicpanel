function MZMP.SubmitOrder(src, sessionId, originalState, currentState, originalProps)
    local session = MZMP.GetSession(sessionId)
    if not session or session.mechanicSrc ~= src then
        return false, 'Sessão inválida.'
    end

    if Config.Security.revalidateVehicleOnSubmit then
        local ok, message = MZMP.ValidateSession(session)
        if not ok then
            return false, message
        end
    end

    local bay = Config.Bays[session.bayId]
    if not bay then
        return false, 'Baia não encontrada.'
    end

    local orderState = currentState or {}
    originalState = originalState or {}
    local quote = MechanicShared.BuildQuote(originalState, orderState, bay.laborMultiplier or 1.0)

    if quote.total <= 0 or not quote.lines or #quote.lines <= 0 then
        return false, 'Nenhuma alteração foi selecionada.'
    end

    session.originalState = originalState
    session.currentState = orderState
    session.originalProps = MZMP.NormalizeOriginalProps(originalProps)
    session.quote = quote

    if session.bypassPayment then
        return true, { type = 'approved', bypass = true }
    end

    local ownerSrc, ownerPlayer, citizenid = MZMP.GetPlayerByPlateOwner(session.plate)
    if not ownerSrc and Config.Panel.allowNonOwnedVehiclePaymentByDriver then
        ownerSrc, ownerPlayer, citizenid = MZMP.FindClosestDriverPayer(session.netId)
    end

    if not ownerSrc or not ownerPlayer then
        return false, 'Proprietário do veículo não está disponível para aprovar.'
    end

    local vehicleCoords = MZMP.GetVehicleCoords(session.netId)
    local ownerCoords = MZMP.GetPlayerCoords(ownerSrc)
    if Config.Panel.requireOwnerNearby and vehicleCoords and ownerCoords then
        if #(vehicleCoords - ownerCoords) > Config.Panel.ownerPayDistance then
            return false, 'O proprietário precisa estar perto do veículo.'
        end
    end

    session.ownerSrc = ownerSrc
    session.ownerCitizenid = citizenid

    local mechanicCitizenid, mechanicName = MZMP.GetMechanicIdentity(src)
    local requestId = ('req:%s:%s'):format(sessionId, math.random(1000, 9999))
    local request = {
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

    MZMP.RemovePendingApprovalBySession(sessionId)
    MZMP.SetPendingApproval(requestId, request)

    return true, {
        type = 'awaiting_owner',
        ownerSrc = ownerSrc,
        ownerPayload = {
            requestId = requestId,
            total = quote.total,
            subtotal = quote.subtotal,
            labor = quote.labor,
            lines = quote.lines,
            plate = session.plate,
            mechanicName = mechanicName,
            shopLabel = bay.label,
        }
    }
end

function MZMP.HandleOwnerApproval(src, requestId, accepted)
    local req = MZMP.GetPendingApproval(requestId)
    if not req or req.ownerSrc ~= src then
        return false, 'Pedido inválido.'
    end

    local session = MZMP.GetSession(req.sessionId)
    if not session then
        MZMP.RemovePendingApproval(requestId)
        return false, 'Sessão não encontrada.', { closeOwnerRequest = true }
    end

    local ownerPlayer = QBCore.Functions.GetPlayer(src)
    if not ownerPlayer then
        return false, 'Jogador inválido.'
    end

    if not accepted then
        MZMP.RemovePendingApproval(requestId)
        return true, nil, {
            closeOwnerRequest = true,
            mechanicSrc = req.mechanicSrc,
            mechanicState = { type = 'declined' }
        }
    end

    if Config.Security.revalidateVehicleOnApproval then
        local ok, message = MZMP.ValidateSession(session, { requireOwnerNearby = true })
        if not ok then
            MZMP.RemovePendingApproval(requestId)
            return false, message, { closeOwnerRequest = true, mechanicSrc = req.mechanicSrc }
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
        MZMP.RemovePendingApproval(requestId)
        return false, 'O proprietário não possui dinheiro suficiente.', { closeOwnerRequest = true, mechanicSrc = req.mechanicSrc }
    end

    MZMP.RemovePendingApproval(requestId)
    session.paid = true
    session.paidFrom = paidFrom
    session.total = total
    session.quote = req.quote

    return true, nil, {
        closeOwnerRequest = true,
        mechanicSrc = req.mechanicSrc,
        mechanicState = { type = 'approved' }
    }
end

function MZMP.SaveApprovedProps(src, sessionId, clientProps)
    local session = MZMP.GetSession(sessionId)
    if not session or session.mechanicSrc ~= src then
        return false, 'Sessão inválida.'
    end

    if not session.bypassPayment and not session.paid then
        return false, 'Pagamento ainda não confirmado.'
    end

    if Config.Security.revalidateVehicleOnSave then
        local ok, message = MZMP.ValidateSession(session)
        if not ok then
            return false, message
        end
    end

    local plate = MZMP.Trim(session.plate)
    local row = MySQL.single.await('SELECT citizenid, mods FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    local existingDbProps = row and MZMP.DecodeJson(row.mods) or {}
    local finalProps = MZMP.BuildFinalProps(session, clientProps or {}, existingDbProps)

    if row then
        MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', {
            json.encode(finalProps),
            plate
        })
    end

    local mechanicCitizenid = select(1, MZMP.GetMechanicIdentity(src))

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
        MZMP.SerializeState(session.quote and session.quote.lines or {}),
        MZMP.SerializeState(session.currentState or {}),
        MZMP.SerializeState(session.originalProps or {}),
        MZMP.SerializeState(finalProps or {}),
        session.quote and session.quote.subtotal or 0,
        session.quote and session.quote.labor or 0,
        session.quote and session.quote.total or 0,
        'paid',
        session.paidFrom or 'bypass',
        session.bypassPayment and 1 or 0
    })

    MZMP.LogServiceAction({
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

    MZMP.RemovePendingApprovalBySession(sessionId)
    MZMP.RemoveSession(sessionId)
    return true
end
