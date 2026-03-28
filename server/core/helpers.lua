function MZMP.Trim(str)
    return (str and str:gsub('^%s*(.-)%s*$', '%1')) or ''
end

function MZMP.DeepCopy(value)
    if type(value) ~= 'table' then return value end
    local copied = {}
    for k, v in pairs(value) do
        copied[k] = MZMP.DeepCopy(v)
    end
    return copied
end

function MZMP.DecodeJson(value)
    if type(value) == 'table' then
        return MZMP.DeepCopy(value)
    end

    if type(value) ~= 'string' or value == '' then
        return nil
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return nil
end

function MZMP.SerializeState(state)
    return json.encode(state or {})
end

function MZMP.IsAdmin(src)
    return QBCore.Functions.HasPermission(src, Config.Access.adminGroups)
end

function MZMP.GetPlayersList()
    if QBCore.Functions.GetPlayers then
        return QBCore.Functions.GetPlayers()
    end
    return GetPlayers()
end

function MZMP.GetPlayerByCitizen(citizenid)
    for _, src in ipairs(MZMP.GetPlayersList()) do
        local player = QBCore.Functions.GetPlayer(tonumber(src))
        if player and player.PlayerData.citizenid == citizenid then
            return tonumber(src), player
        end
    end
end

function MZMP.GetPlayerByPlateOwner(plate)
    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not row or not row.citizenid then return nil, nil, nil end

    local src, player = MZMP.GetPlayerByCitizen(row.citizenid)
    return src, player, row.citizenid
end

function MZMP.FindClosestDriverPayer(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return nil, nil, nil end

    local ped = GetPedInVehicleSeat(vehicle, -1)
    if ped == 0 then return nil, nil, nil end

    local ownerSrc = NetworkGetEntityOwner(ped)
    if not ownerSrc then return nil, nil, nil end

    local player = QBCore.Functions.GetPlayer(ownerSrc)
    if not player then return nil, nil, nil end

    return ownerSrc, player, player.PlayerData.citizenid
end

function MZMP.GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function MZMP.GetMechanicIdentity(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil, ('ID %s'):format(src) end

    local citizenid = player.PlayerData.citizenid
    local charinfo = player.PlayerData.charinfo or {}
    local fullName = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):gsub('^%s*(.-)%s*$', '%1')

    if fullName == '' then
        fullName = ('ID %s'):format(src)
    end

    return citizenid, fullName
end

function MZMP.Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function MZMP.BuildCoordsPayload(coords)
    if not Config.Logging or not Config.Logging.storeCoords then return nil end
    if not coords then return nil end

    return {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
    }
end
