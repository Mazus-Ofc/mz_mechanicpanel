QBCore = exports['qb-core']:GetCoreObject()
MZMP = MZMP or {}

MZMP.StateToPropKeys = {
    engine = { 'modEngine' },
    brakes = { 'modBrakes' },
    transmission = { 'modTransmission' },
    suspension = { 'modSuspension' },
    armor = { 'modArmor' },
    turbo = { 'modTurbo' },

    paint_primary = { 'color1', 'customPrimaryColor' },
    paint_secondary = { 'color2', 'customSecondaryColor' },
    pearlescent = { 'pearlescentColor' },
    wheel_color = { 'wheelColor' },
    livery = { 'modLivery', 'livery' },

    wheel_type = { 'wheels' },
    wheels = { 'modFrontWheels', 'modBackWheels' },
    custom_tires = { 'modCustomTiresF', 'modCustomTiresR' },
    bulletproof_tires = { 'modBulletproofTires' },
    tire_smoke = { 'modSmokeEnabled', 'tyreSmokeColor' },

    tint = { 'windowTint' },
    xenon = { 'modXenon', 'xenonColor' },
    neon = { 'neonEnabled', 'neonColor' },
    plate = { 'plateIndex' },

    spoiler = { 'modSpoilers' },
    front_bumper = { 'modFrontBumper' },
    rear_bumper = { 'modRearBumper' },
    side_skirt = { 'modSideSkirt' },
    exhaust = { 'modExhaust' },
    frame = { 'modFrame' },
    grille = { 'modGrille' },
    hood = { 'modHood' },
    left_fender = { 'modFender' },
    right_fender = { 'modRightFender' },
    roof = { 'modRoof' },
    plate_holder = { 'modPlateHolder' },
    trim_design = { 'modTrimA' },
    ornaments = { 'modOrnaments' },
    dashboard = { 'modDashboard' },
    dial = { 'modDial' },
    door_speaker = { 'modDoorSpeaker' },
    seats = { 'modSeats' },
    steering_wheel = { 'modSteeringWheel' },
    shifter = { 'modShifterLeavers' },
    plaques = { 'modAPlate' },
    speakers = { 'modSpeakers' },
    trunk = { 'modTrunk' },
    hydraulics = { 'modHydraulics' },
    engine_block = { 'modEngineBlock' },
    air_filter = { 'modAirFilter' },
    struts = { 'modStruts' },
    arch_cover = { 'modArchCover' },
    aerials = { 'modAerials' },
    trim = { 'modTrimB' },
    tank = { 'modTank' },
    windows = { 'modWindows' },

    extras = { 'extras' },
    service_engine = { 'engineHealth' },
    service_body = { 'bodyHealth' },
    service_clean = { 'dirtLevel' },
    service_full = { 'engineHealth', 'bodyHealth', 'tankHealth', 'dirtLevel' },
}

function MZMP.Debug(...)
    if Config.Debug then
        print('^5[mz_mechanicpanel]^7', ...)
    end
end
