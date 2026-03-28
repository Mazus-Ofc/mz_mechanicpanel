function MZMP.GetVehicleEntity(netId)
    local entity = NetworkGetEntityFromNetworkId(netId or 0)
    if entity == 0 or not DoesEntityExist(entity) then return 0 end
    return entity
end

function MZMP.GetVehicleCoords(netId)
    local entity = MZMP.GetVehicleEntity(netId)
    if entity == 0 then return nil end
    return GetEntityCoords(entity)
end

function MZMP.GetVehiclePlateByNetId(netId)
    local entity = MZMP.GetVehicleEntity(netId)
    if entity == 0 then return '' end
    return MZMP.Trim(GetVehicleNumberPlateText(entity))
end

function MZMP.IsVehicleInBay(netId, bay)
    local coords = MZMP.GetVehicleCoords(netId)
    if not coords then return false end

    local point = vec3(bay.vehiclePoint.x, bay.vehiclePoint.y, bay.vehiclePoint.z)
    return #(coords - point) <= (bay.vehicleDistance or Config.Panel.vehicleDistance)
end

function MZMP.CanUsePanel(src, bay)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return false, 'Jogador inválido.'
    end

    if MZMP.IsAdmin(src) then
        return true
    end

    local job = player.PlayerData.job or {}
    local jobName = job.name

    if Config.Access.requireJobTypeMechanic and job.type ~= 'mechanic' then
        return false, 'Você não é mecânico.'
    end

    local allowed = false
    if bay.strictShopJob then
        allowed = (jobName == bay.shop)
    else
        allowed = Config.Access.allowedJobs[jobName] == true or job.type == 'mechanic'
    end

    if not allowed then
        return false, 'Você não tem acesso a esta oficina.'
    end

    return true
end

function MZMP.ValidateSession(session, opts)
    opts = opts or {}

    local bay = Config.Bays[session.bayId]
    if not bay then
        return false, 'Baia não encontrada.'
    end

    local vehicle = MZMP.GetVehicleEntity(session.netId)
    if vehicle == 0 then
        return false, 'Veículo não encontrado.'
    end

    if Config.Security.requirePlateMatchOnSave then
        local serverPlate = MZMP.GetVehiclePlateByNetId(session.netId)
        if serverPlate == '' or serverPlate ~= MZMP.Trim(session.plate) then
            return false, 'A placa do veículo não confere mais com a sessão.'
        end
    end

    if not MZMP.IsVehicleInBay(session.netId, bay) then
        return false, 'O veículo saiu da baia.'
    end

    if not MZMP.IsAdmin(session.mechanicSrc) then
        local mechanicCoords = MZMP.GetPlayerCoords(session.mechanicSrc)
        if not mechanicCoords or #(mechanicCoords - bay.marker) > ((bay.interactDistance or Config.Panel.interactDistance) + 2.5) then
            return false, 'O mecânico saiu da área da oficina.'
        end
    end

    if opts.requireOwnerNearby and session.ownerSrc and Config.Panel.requireOwnerNearby then
        local vehicleCoords = GetEntityCoords(vehicle)
        local ownerCoords = MZMP.GetPlayerCoords(session.ownerSrc)
        if not ownerCoords or #(vehicleCoords - ownerCoords) > Config.Panel.ownerPayDistance then
            return false, 'O proprietário precisa estar perto do veículo.'
        end
    end

    return true, nil, vehicle, bay
end
