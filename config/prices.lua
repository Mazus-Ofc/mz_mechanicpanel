Config = Config or {}

Config.Prices = {
    performance = {
        engine = { [0] = 0, [1] = 5000, [2] = 9000, [3] = 15000, [4] = 25000 },
        brakes = { [0] = 0, [1] = 3500, [2] = 6500, [3] = 10500 },
        transmission = { [0] = 0, [1] = 4200, [2] = 7600, [3] = 12500 },
        suspension = { [0] = 0, [1] = 2800, [2] = 5400, [3] = 9200, [4] = 14000 },
        armor = { [0] = 0, [1] = 7000, [2] = 12000, [3] = 20000, [4] = 30000, [5] = 45000 },
        turbo = { install = 12000, remove = 0 },
    },
    cosmetic = {
        visualPart = 1800,
        premiumVisualPart = 3200,
        wheelType = 1200,
        wheels = 4800,
        customTires = 900,
        bulletproofTires = 2500,
        tireSmoke = 1800,
        plate = 700,
        tint = 1200,
        xenon = 3500,
        neon = 4200,
        livery = 4500,
        primaryPaint = 3200,
        secondaryPaint = 2200,
        pearlescent = 1500,
        wheelColor = 900,
        extraToggle = 950,
    },
    service = {
        engineRepair = 2500,
        bodyRepair = 3000,
        fullRepair = 8500,
        tiresRepair = 1500,
        cleaning = 500,
    },
    labor = {
        base = 350,
        performance = 500,
        visual = 250,
        paint = 400,
        service = 200,
    }
}
