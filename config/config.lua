Config = Config or {}

Config.Debug = false
Config.CurrencySymbol = '$'
Config.Locale = 'pt-br'

Config.Access = {
    adminGroups = { 'god', 'admin' },
    allowedJobs = {
        mechanic = true,
        bennys = true,
        beeker = true,
    },
    requireJobTypeMechanic = false,
}

Config.Panel = {
    command = 'mechpanel',
    cancelCommand = 'mechcancel',
    openKey = 38, -- E

    markerType = 2,
    markerScale = vec3(0.45, 0.45, 0.45),
    markerColor = { r = 0, g = 180, b = 255, a = 180 },

    interactDistance = 2.0,
    vehicleDistance = 3.2,
    bayRadius = 3.6,

    requireVehicleStopped = true,
    requireVehicleEmpty = true,
    lockVehicleWhileEditing = true,
    ownerPayDistance = 10.0,
    requireOwnerNearby = true,
    allowAdminBypassPayment = true,
    allowNonOwnedVehiclePaymentByDriver = true,
    closeDistanceTolerance = 14.0,
    autoFreezeVehicle = true,
}

Config.Security = {
    revalidateVehicleOnSubmit = true,
    revalidateVehicleOnApproval = true,
    revalidateVehicleOnSave = true,
    requirePlateMatchOnSave = true,
    persistOnlyTouchedProps = true,
}

Config.Camera = {
    default = {
        sideOffset = vec3(-3.9, 2.1, 1.15),
        rot = vec3(-10.0, 0.0, 215.0),
        fov = 36.0,
    },
    zoomStep = 0.9,
    minFov = 18.0,
    maxFov = 55.0,
}

Config.RepairItems = {
    basic = 'repairkit',
    advanced = 'advancedrepairkit',
    tire = 'tirerepairkit',
    cleaning = 'cleaningkit',
    toolbox = 'veh_toolbox',
    maxUseDistance = 5.0,
    refundOnCancel = true,
    reserveTimeoutSeconds = 120,
}

Config.WindowTints = {
    { id = 0, label = 'Sem Insulfilm' },
    { id = 1, label = 'Leve' },
    { id = 2, label = 'Médio' },
    { id = 3, label = 'Escuro' },
    { id = 4, label = 'Muito Escuro' },
    { id = 5, label = 'Limousine' },
    { id = 6, label = 'Verde' },
}

Config.PlateIndexes = {
    { id = 0, label = 'Azul/Branca' },
    { id = 1, label = 'Amarela/Preta' },
    { id = 2, label = 'Azul/Branca 2' },
    { id = 3, label = 'Preta/Branca SA' },
    { id = 4, label = 'Preta/Amarela SA' },
    { id = 5, label = 'Branca/Verde SA' },
}

Config.XenonPresets = {
    { id = 255, label = 'Branco Padrão' },
    { id = 0, label = 'Azul' },
    { id = 1, label = 'Elétrico' },
    { id = 2, label = 'Verde Menta' },
    { id = 3, label = 'Verde Lima' },
    { id = 4, label = 'Amarelo' },
    { id = 5, label = 'Dourado' },
    { id = 6, label = 'Laranja' },
    { id = 7, label = 'Vermelho' },
    { id = 8, label = 'Rosa' },
    { id = 9, label = 'Roxo' },
    { id = 10, label = 'Preto' },
}

Config.NeonPresets = {
    { label = 'Branco', hex = '#ffffff' },
    { label = 'Azul', hex = '#3b82f6' },
    { label = 'Ciano', hex = '#06b6d4' },
    { label = 'Verde', hex = '#22c55e' },
    { label = 'Amarelo', hex = '#eab308' },
    { label = 'Laranja', hex = '#f97316' },
    { label = 'Vermelho', hex = '#ef4444' },
    { label = 'Rosa', hex = '#ec4899' },
    { label = 'Roxo', hex = '#8b5cf6' },
}

Config.PaintPresets = {
    { label = 'Branco Gelo', index = 111, hex = '#f2f5f7' },
    { label = 'Preto', index = 0, hex = '#111111' },
    { label = 'Cinza Grafite', index = 4, hex = '#353535' },
    { label = 'Prata', index = 5, hex = '#999999' },
    { label = 'Vermelho', index = 27, hex = '#b91c1c' },
    { label = 'Vermelho Vinho', index = 39, hex = '#6b0f1a' },
    { label = 'Laranja', index = 38, hex = '#ea580c' },
    { label = 'Amarelo', index = 88, hex = '#facc15' },
    { label = 'Verde', index = 55, hex = '#16a34a' },
    { label = 'Verde Escuro', index = 49, hex = '#14532d' },
    { label = 'Azul', index = 64, hex = '#2563eb' },
    { label = 'Azul Escuro', index = 62, hex = '#1d4ed8' },
    { label = 'Roxo', index = 71, hex = '#7c3aed' },
    { label = 'Rosa', index = 135, hex = '#ec4899' },
    { label = 'Areia', index = 95, hex = '#c2b280' },
    { label = 'Dourado', index = 99, hex = '#d4af37' },
}

Config.WheelTypes = {
    { id = 0, label = 'Esportivo' },
    { id = 1, label = 'Muscle' },
    { id = 2, label = 'Lowrider' },
    { id = 3, label = 'SUV' },
    { id = 4, label = 'Off-road' },
    { id = 5, label = 'Tuner' },
    { id = 6, label = 'Bike' },
    { id = 7, label = 'High End' },
    { id = 8, label = 'Benny Original' },
    { id = 9, label = 'Benny Bespoke' },
    { id = 10, label = 'Open Wheel' },
    { id = 11, label = 'Street' },
    { id = 12, label = 'Track' },
}

Config.Bays = {
    bennys_1 = {
        label = 'Benny\'s - Baia 1',
        shop = 'bennys',
        marker = vec3(-205.65, -1327.80, 30.89),
        vehiclePoint = vec4(-202.95, -1327.85, 30.89, 270.0),
        interactDistance = 2.0,
        vehicleDistance = 3.6,
        laborMultiplier = 1.0,
        strictShopJob = false,
        camera = {
            sideOffset = vec3(-4.1, 2.15, 1.15),
            rot = vec3(-9.0, 0.0, 220.0),
            fov = 36.0,
        }
    },

    bennys_2 = {
        label = 'Benny\'s - Baia 2',
        shop = 'bennys',
        marker = vec3(-198.75, -1324.30, 30.89),
        vehiclePoint = vec4(-196.35, -1324.20, 30.89, 270.0),
        interactDistance = 2.0,
        vehicleDistance = 3.6,
        laborMultiplier = 1.0,
        strictShopJob = false,
    }
}