local function buildOrderMetadata(session, extra)
    extra = extra or {}

    local metadata = {
        quoteLines = session.quote and session.quote.lines or {},
        approvedState = session.currentState or {},
        originalState = session.originalState or {},
        originalProps = session.originalProps or {},
        paidFrom = session.paidFrom,
        bypassPayment = session.bypassPayment == true,
    }

    for key, value in pairs(extra) do
        metadata[key] = value
    end

    return metadata
end

function MZMP.CreateOrUpdateOrder(session, data)
    data = data or {}

    local ownerCitizenid = data.ownerCitizenid or session.ownerCitizenid
    local mechanicCitizenid = data.mechanicCitizenid or session.mechanicCitizenid or select(1, MZMP.GetMechanicIdentity(session.mechanicSrc))

    session.ownerCitizenid = ownerCitizenid or session.ownerCitizenid
    session.mechanicCitizenid = mechanicCitizenid or session.mechanicCitizenid

    if session.orderId then
        MySQL.update.await([[
            UPDATE mechanic_orders
            SET bay_id = ?, plate = ?, vehicle_model = ?, owner_citizenid = ?, mechanic_citizenid = ?, shop_label = ?,
                items_json = ?, approved_state_json = ?, original_props_json = ?, subtotal = ?, labor = ?, total = ?,
                status = ?, paid_from = ?, bypass_payment = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            session.bayId,
            session.plate,
            session.vehicleModel,
            ownerCitizenid,
            mechanicCitizenid,
            session.shopLabel,
            MZMP.SerializeState(session.quote and session.quote.lines or {}),
            MZMP.SerializeState(session.currentState or {}),
            MZMP.SerializeState(session.originalProps or {}),
            session.quote and session.quote.subtotal or 0,
            session.quote and session.quote.labor or 0,
            session.quote and session.quote.total or 0,
            data.status or 'pending',
            data.paidFrom,
            session.bypassPayment and 1 or 0,
            MZMP.SerializeState(data.metadata or {}),
            session.orderId
        })

        return session.orderId
    end

    local orderId = MySQL.insert.await([[
        INSERT INTO mechanic_orders (
            session_id, bay_id, plate, vehicle_model, owner_citizenid, mechanic_citizenid, shop_label,
            items_json, approved_state_json, original_props_json, final_props_json,
            subtotal, labor, total, status, paid_from, bypass_payment, metadata
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        session.sessionId,
        session.bayId,
        session.plate,
        session.vehicleModel,
        ownerCitizenid,
        mechanicCitizenid,
        session.shopLabel,
        MZMP.SerializeState(session.quote and session.quote.lines or {}),
        MZMP.SerializeState(session.currentState or {}),
        MZMP.SerializeState(session.originalProps or {}),
        nil,
        session.quote and session.quote.subtotal or 0,
        session.quote and session.quote.labor or 0,
        session.quote and session.quote.total or 0,
        data.status or 'pending',
        data.paidFrom,
        session.bypassPayment and 1 or 0,
        MZMP.SerializeState(data.metadata or {})
    })

    session.orderId = orderId
    return orderId
end

function MZMP.UpdateOrderStatus(session, status, opts)
    if not session or not session.orderId then return end
    opts = opts or {}

    MySQL.update.await([[
        UPDATE mechanic_orders
        SET status = ?, paid_from = COALESCE(?, paid_from), metadata = COALESCE(?, metadata), updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], {
        status,
        opts.paidFrom,
        opts.metadata and MZMP.SerializeState(opts.metadata) or nil,
        session.orderId
    })
end

function MZMP.FinalizeOrder(session, ownerCitizenid, mechanicCitizenid, finalProps)
    if not session or not session.orderId then return false end

    MySQL.update.await([[
        UPDATE mechanic_orders
        SET owner_citizenid = ?, mechanic_citizenid = ?, final_props_json = ?, status = ?, paid_from = ?, metadata = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], {
        ownerCitizenid,
        mechanicCitizenid,
        MZMP.SerializeState(finalProps or {}),
        'completed',
        session.paidFrom or 'bypass',
        MZMP.SerializeState(buildOrderMetadata(session, { finalPropsSaved = true })),
        session.orderId
    })

    return true
end

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

    local mechanicCitizenid, mechanicName = MZMP.GetMechanicIdentity(src)
    session.mechanicCitizenid = mechanicCitizenid

    if session.bypassPayment then
        session.paid = true
        session.paidFrom = 'bypass'
        session.total = quote.total

        session.orderId = MZMP.CreateOrUpdateOrder(session, {
            status = 'approved',
            paidFrom = 'bypass',
            mechanicCitizenid = mechanicCitizenid,
            metadata = buildOrderMetadata(session, {
                approvalType = 'admin_bypass',
            })
        })

        MZMP.LogServiceAction({
            orderId = session.orderId,
            sessionId = session.sessionId,
            bayId = session.bayId,
            plate = session.plate,
            vehicleModel = session.vehicleModel,
            ownerCitizenid = session.ownerCitizenid,
            mechanicCitizenid = mechanicCitizenid,
            shopLabel = session.shopLabel,
            action = 'order_approved',
            status = 'approved',
            value = quote.total,
            metadata = {
                approvalType = 'admin_bypass',
                quote = quote.lines or {},
            }
        })

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

    session.orderId = MZMP.CreateOrUpdateOrder(session, {
        status = 'pending',
        ownerCitizenid = citizenid,
        mechanicCitizenid = mechanicCitizenid,
        metadata = buildOrderMetadata(session, {
            ownerSrc = ownerSrc,
            mechanicName = mechanicName,
            requestedAt = os.time(),
        })
    })

    MZMP.LogServiceAction({
        orderId = session.orderId,
        sessionId = session.sessionId,
        bayId = session.bayId,
        plate = session.plate,
        vehicleModel = session.vehicleModel,
        ownerCitizenid = citizenid,
        mechanicCitizenid = mechanicCitizenid,
        shopLabel = session.shopLabel,
        action = 'order_submitted',
        status = 'pending',
        value = quote.total,
        metadata = {
            quote = quote.lines or {},
            subtotal = quote.subtotal,
            labor = quote.labor,
            ownerSrc = ownerSrc,
        }
    })

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
        orderId = session.orderId,
        createdAt = os.time(),
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
        MZMP.UpdateOrderStatus(session, 'declined', {
            metadata = buildOrderMetadata(session, {
                declineSource = src,
                declinedAt = os.time(),
            })
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
            action = 'order_declined',
            status = 'declined',
            value = req.total or 0,
            metadata = {
                declinedBy = src,
            }
        })

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
            MZMP.UpdateOrderStatus(session, 'cancelled', {
                metadata = buildOrderMetadata(session, {
                    approvalValidationFailed = true,
                    validationMessage = message,
                })
            })
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

    MZMP.UpdateOrderStatus(session, 'approved', {
        paidFrom = paidFrom,
        metadata = buildOrderMetadata(session, {
            approvedAt = os.time(),
            approvedBy = src,
        })
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
        action = 'order_approved',
        status = 'approved',
        value = total,
        metadata = {
            approvedBy = src,
            paidFrom = paidFrom,
        }
    })

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

    if session.orderId then
        local orderRow = MySQL.single.await('SELECT id, status FROM mechanic_orders WHERE id = ? LIMIT 1', { session.orderId })
        if not orderRow then
            return false, 'Ordem de serviço não encontrada.'
        end

        if session.bypassPayment then
            if orderRow.status ~= 'approved' then
                return false, 'A ordem não está pronta para finalizar.'
            end
        elseif orderRow.status ~= 'approved' then
            return false, 'A ordem ainda não foi aprovada.'
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
    local ownerCitizenid = row and row.citizenid or session.ownerCitizenid

    MZMP.FinalizeOrder(session, ownerCitizenid, mechanicCitizenid, finalProps)

    MZMP.LogServiceAction({
        orderId = session.orderId,
        sessionId = session.sessionId,
        bayId = session.bayId,
        plate = plate,
        vehicleModel = session.vehicleModel,
        ownerCitizenid = ownerCitizenid,
        mechanicCitizenid = mechanicCitizenid,
        shopLabel = session.shopLabel,
        action = 'service_completed',
        status = 'completed',
        value = session.quote and session.quote.total or 0,
        metadata = {
            shop = session.shopLabel,
            lines = session.quote and session.quote.lines or {},
            paidFrom = session.paidFrom or 'bypass',
            approvedState = session.currentState or {},
            finalPropsSaved = true,
        }
    })

    MZMP.RemovePendingApprovalBySession(sessionId)
    MZMP.RemoveSession(sessionId)
    return true
end

function MZMP.StartOrderTimeoutThread()
    CreateThread(function()
        while true do
            Wait((Config.Orders and Config.Orders.cleanupIntervalMs) or 10000)

            local now = os.time()
            local timeout = (Config.Orders and Config.Orders.timeoutSeconds) or 180

            for requestId, req in pairs(MZMP.Store.PendingApprovals) do
                if req and req.createdAt and (now - req.createdAt) >= timeout then
                    local session = MZMP.GetSession(req.sessionId)
                    if session and session.orderId then
                        MZMP.UpdateOrderStatus(session, 'expired', {
                            metadata = buildOrderMetadata(session, {
                                expiredAt = now,
                                timeoutSeconds = timeout,
                            })
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
                            action = 'order_expired',
                            status = 'expired',
                            value = req.total or 0,
                            metadata = {
                                timeoutSeconds = timeout,
                            }
                        })
                    end

                    if req.ownerSrc then
                        TriggerClientEvent('mz_mechanicpanel:client:closeOwnerRequest', req.ownerSrc)
                    end

                    if req.mechanicSrc then
                        TriggerClientEvent('mz_mechanicpanel:client:orderState', req.mechanicSrc, {
                            type = 'error',
                            message = 'O orçamento expirou e precisa ser enviado novamente.'
                        })
                    end

                    MZMP.RemovePendingApproval(requestId)
                    if session then
                        MZMP.RemoveSession(req.sessionId)
                    end
                end
            end
        end
    end)
end
