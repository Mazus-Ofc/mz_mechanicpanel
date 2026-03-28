MechanicShared = MechanicShared or {}

MechanicShared.Categories = {
    { key = 'performance', label = 'Performance', icon = 'engine' },
    { key = 'paint', label = 'Pintura', icon = 'paint' },
    { key = 'wheels', label = 'Rodas', icon = 'wheel' },
    { key = 'lighting', label = 'Iluminação', icon = 'xenon' },
    { key = 'body', label = 'Exterior', icon = 'body' },
    { key = 'interior', label = 'Interior', icon = 'interior' },
    { key = 'extras', label = 'Extras', icon = 'extras' },
    { key = 'service', label = 'Serviços', icon = 'service' },
}

MechanicShared.Sections = {
    engine = { key = 'engine', category = 'performance', label = 'Motor', icon = 'engine', description = 'Define o nível de preparação do motor.', mode = 'mod', modType = 11, priceKind = 'performance', priceKey = 'engine', laborKind = 'performance' },
    brakes = { key = 'brakes', category = 'performance', label = 'Freios', icon = 'brakes', description = 'Ajusta a potência de frenagem.', mode = 'mod', modType = 12, priceKind = 'performance', priceKey = 'brakes', laborKind = 'performance' },
    transmission = { key = 'transmission', category = 'performance', label = 'Transmissão', icon = 'transmission', description = 'Melhora a troca de marchas.', mode = 'mod', modType = 13, priceKind = 'performance', priceKey = 'transmission', laborKind = 'performance' },
    suspension = { key = 'suspension', category = 'performance', label = 'Suspensão', icon = 'suspension', description = 'Controla altura e resposta da suspensão.', mode = 'mod', modType = 15, priceKind = 'performance', priceKey = 'suspension', laborKind = 'performance' },
    turbo = { key = 'turbo', category = 'performance', label = 'Turbo', icon = 'turbo', description = 'Ativa ou remove o turbo.', mode = 'toggleMod', modType = 18, priceKind = 'performanceToggle', priceKey = 'turbo', laborKind = 'performance' },
    armor = { key = 'armor', category = 'performance', label = 'Blindagem', icon = 'armor', description = 'Aumenta a resistência do veículo.', mode = 'mod', modType = 16, priceKind = 'performance', priceKey = 'armor', laborKind = 'performance' },

    paint_primary = { key = 'paint_primary', category = 'paint', label = 'Pintura Primária', icon = 'paint', description = 'Cor principal do veículo.', mode = 'paintPrimary', priceKind = 'flat', priceKey = 'primaryPaint', laborKind = 'paint' },
    paint_secondary = { key = 'paint_secondary', category = 'paint', label = 'Pintura Secundária', icon = 'paint2', description = 'Cor secundária do veículo.', mode = 'paintSecondary', priceKind = 'flat', priceKey = 'secondaryPaint', laborKind = 'paint' },
    pearlescent = { key = 'pearlescent', category = 'paint', label = 'Perolizado', icon = 'pearlescent', description = 'Acabamento perolizado da pintura.', mode = 'pearlescent', priceKind = 'flat', priceKey = 'pearlescent', laborKind = 'paint' },
    wheel_color = { key = 'wheel_color', category = 'paint', label = 'Cor da Roda', icon = 'wheel', description = 'Altera a cor das rodas.', mode = 'wheelColor', priceKind = 'flat', priceKey = 'wheelColor', laborKind = 'paint' },
    livery = { key = 'livery', category = 'paint', label = 'Livery', icon = 'livery', description = 'Aplica adesivos e desenhos do veículo.', mode = 'livery', priceKind = 'flat', priceKey = 'livery', laborKind = 'visual' },

    wheel_type = { key = 'wheel_type', category = 'wheels', label = 'Tipo de Roda', icon = 'wheel', description = 'Troca a família das rodas.', mode = 'wheelType', priceKind = 'flat', priceKey = 'wheelType', laborKind = 'visual' },
    wheels = { key = 'wheels', category = 'wheels', label = 'Rodas', icon = 'wheel2', description = 'Define o modelo de roda.', mode = 'frontWheels', priceKind = 'flat', priceKey = 'wheels', laborKind = 'visual' },
    custom_tires = { key = 'custom_tires', category = 'wheels', label = 'Pneus Personalizados', icon = 'tire', description = 'Ativa a variação de pneus personalizados.', mode = 'wheelVariation', priceKind = 'flat', priceKey = 'customTires', laborKind = 'visual' },
    bulletproof_tires = { key = 'bulletproof_tires', category = 'wheels', label = 'Pneus à Prova de Bala', icon = 'shieldtire', description = 'Impede estouro dos pneus.', mode = 'bulletproofTires', priceKind = 'flat', priceKey = 'bulletproofTires', laborKind = 'visual' },
    tire_smoke = { key = 'tire_smoke', category = 'wheels', label = 'Fumaça do Pneu', icon = 'smoke', description = 'Define cor da fumaça do pneu.', mode = 'tireSmoke', priceKind = 'flat', priceKey = 'tireSmoke', laborKind = 'visual' },

    tint = { key = 'tint', category = 'lighting', label = 'Insulfilm', icon = 'tint', description = 'Escurece os vidros.', mode = 'tint', priceKind = 'flat', priceKey = 'tint', laborKind = 'visual' },
    xenon = { key = 'xenon', category = 'lighting', label = 'Xenon', icon = 'xenon', description = 'Ativa farol xenon e escolhe a cor.', mode = 'xenon', priceKind = 'flat', priceKey = 'xenon', laborKind = 'visual' },
    neon = { key = 'neon', category = 'lighting', label = 'Neon', icon = 'neon', description = 'Configura cor e lados do neon.', mode = 'neon', priceKind = 'flat', priceKey = 'neon', laborKind = 'visual' },
    plate = { key = 'plate', category = 'lighting', label = 'Modelo da Placa', icon = 'plate', description = 'Troca o estilo visual da placa.', mode = 'plate', priceKind = 'flat', priceKey = 'plate', laborKind = 'visual' },

    spoiler = { key = 'spoiler', category = 'body', label = 'Aerofólio', icon = 'spoiler', description = 'Aerofólio traseiro.', mode = 'mod', modType = 0, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    front_bumper = { key = 'front_bumper', category = 'body', label = 'Parachoque Dianteiro', icon = 'bumperf', description = 'Acabamento frontal do veículo.', mode = 'mod', modType = 1, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    rear_bumper = { key = 'rear_bumper', category = 'body', label = 'Parachoque Traseiro', icon = 'bumperr', description = 'Acabamento traseiro.', mode = 'mod', modType = 2, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    side_skirt = { key = 'side_skirt', category = 'body', label = 'Saia Lateral', icon = 'skirt', description = 'Saias laterais do veículo.', mode = 'mod', modType = 3, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    exhaust = { key = 'exhaust', category = 'body', label = 'Escapamento', icon = 'exhaust', description = 'Define o modelo do escapamento.', mode = 'mod', modType = 4, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    frame = { key = 'frame', category = 'body', label = 'Chassi / Frame', icon = 'frame', description = 'Estruturas visuais externas.', mode = 'mod', modType = 5, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    grille = { key = 'grille', category = 'body', label = 'Grade', icon = 'grille', description = 'Grade frontal.', mode = 'mod', modType = 6, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    hood = { key = 'hood', category = 'body', label = 'Capô', icon = 'hood', description = 'Troca o capô do veículo.', mode = 'mod', modType = 7, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    left_fender = { key = 'left_fender', category = 'body', label = 'Paralama Esq.', icon = 'fender', description = 'Paralama esquerdo.', mode = 'mod', modType = 8, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    right_fender = { key = 'right_fender', category = 'body', label = 'Paralama Dir.', icon = 'fender', description = 'Paralama direito.', mode = 'mod', modType = 9, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    roof = { key = 'roof', category = 'body', label = 'Teto', icon = 'roof', description = 'Troca o acabamento do teto.', mode = 'mod', modType = 10, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },

    plate_holder = { key = 'plate_holder', category = 'body', label = 'Suporte da Placa', icon = 'plate', description = 'Moldura e suporte da placa.', mode = 'mod', modType = 25, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    trim_design = { key = 'trim_design', category = 'interior', label = 'Acabamento', icon = 'trim', description = 'Acabamentos internos.', mode = 'mod', modType = 27, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    ornaments = { key = 'ornaments', category = 'interior', label = 'Ornamentos', icon = 'ornament', description = 'Objetos e detalhes do painel.', mode = 'mod', modType = 28, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    dashboard = { key = 'dashboard', category = 'interior', label = 'Painel', icon = 'dashboard', description = 'Painel dianteiro.', mode = 'mod', modType = 29, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    dial = { key = 'dial', category = 'interior', label = 'Mostradores', icon = 'dial', description = 'Mostradores do painel.', mode = 'mod', modType = 30, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    door_speaker = { key = 'door_speaker', category = 'interior', label = 'Som das Portas', icon = 'speaker', description = 'Speakers das portas.', mode = 'mod', modType = 31, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    seats = { key = 'seats', category = 'interior', label = 'Bancos', icon = 'seat', description = 'Modelo dos bancos.', mode = 'mod', modType = 32, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    steering_wheel = { key = 'steering_wheel', category = 'interior', label = 'Volante', icon = 'steering', description = 'Modelo do volante.', mode = 'mod', modType = 33, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    shifter = { key = 'shifter', category = 'interior', label = 'Câmbio', icon = 'shifter', description = 'Alavanca de câmbio.', mode = 'mod', modType = 34, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    plaques = { key = 'plaques', category = 'interior', label = 'Plaquetas', icon = 'plaque', description = 'Plaquetas e tags internas.', mode = 'mod', modType = 35, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    speakers = { key = 'speakers', category = 'interior', label = 'Speakers', icon = 'speaker', description = 'Sistema de som.', mode = 'mod', modType = 36, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    trunk = { key = 'trunk', category = 'interior', label = 'Porta-Malas', icon = 'trunk', description = 'Acabamento do porta-malas.', mode = 'mod', modType = 37, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    hydraulics = { key = 'hydraulics', category = 'interior', label = 'Hidráulica', icon = 'hydraulics', description = 'Sistema hidráulico / lowrider.', mode = 'mod', modType = 38, priceKind = 'flat', priceKey = 'premiumVisualPart', laborKind = 'visual' },
    engine_block = { key = 'engine_block', category = 'body', label = 'Bloco do Motor', icon = 'engine', description = 'Visual do motor.', mode = 'mod', modType = 39, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    air_filter = { key = 'air_filter', category = 'body', label = 'Filtro de Ar', icon = 'filter', description = 'Filtro e admissão.', mode = 'mod', modType = 40, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    struts = { key = 'struts', category = 'body', label = 'Torres / Struts', icon = 'strut', description = 'Barras do cofre.', mode = 'mod', modType = 41, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    arch_cover = { key = 'arch_cover', category = 'body', label = 'Arch Cover', icon = 'arch', description = 'Alargadores e capa do arco.', mode = 'mod', modType = 42, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    aerials = { key = 'aerials', category = 'body', label = 'Antenas', icon = 'aerial', description = 'Antenas e acessórios.', mode = 'mod', modType = 43, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    trim = { key = 'trim', category = 'body', label = 'Trim Externo', icon = 'trim', description = 'Acabamento externo.', mode = 'mod', modType = 44, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    tank = { key = 'tank', category = 'body', label = 'Tanque', icon = 'tank', description = 'Visual do tanque.', mode = 'mod', modType = 45, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },
    windows = { key = 'windows', category = 'body', label = 'Janelas', icon = 'window', description = 'Acabamentos das janelas.', mode = 'mod', modType = 46, priceKind = 'flat', priceKey = 'visualPart', laborKind = 'visual' },

    extras = { key = 'extras', category = 'extras', label = 'Extras', icon = 'extras', description = 'Liga ou desliga extras do veículo.', mode = 'extras', priceKind = 'flat', priceKey = 'extraToggle', laborKind = 'visual' },

    service_engine = { key = 'service_engine', category = 'service', label = 'Reparar Motor', icon = 'repair', description = 'Recupera a saúde do motor.', mode = 'serviceToggle', service = 'engineRepair', priceKind = 'service', priceKey = 'engineRepair', laborKind = 'service' },
    service_body = { key = 'service_body', category = 'service', label = 'Reparar Lataria', icon = 'body', description = 'Recupera a lataria.', mode = 'serviceToggle', service = 'bodyRepair', priceKind = 'service', priceKey = 'bodyRepair', laborKind = 'service' },
    service_tires = { key = 'service_tires', category = 'service', label = 'Reparar Pneus', icon = 'tire', description = 'Conserta pneus estourados.', mode = 'serviceToggle', service = 'tiresRepair', priceKind = 'service', priceKey = 'tiresRepair', laborKind = 'service' },
    service_clean = { key = 'service_clean', category = 'service', label = 'Lavagem', icon = 'clean', description = 'Remove sujeira do veículo.', mode = 'serviceToggle', service = 'cleaning', priceKind = 'service', priceKey = 'cleaning', laborKind = 'service' },
    service_full = { key = 'service_full', category = 'service', label = 'Reparo Completo', icon = 'repairfull', description = 'Reparo completo do veículo.', mode = 'serviceToggle', service = 'fullRepair', priceKind = 'service', priceKey = 'fullRepair', laborKind = 'service' },
}

local function tableEquals(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    return json.encode(a) == json.encode(b)
end

local function addMoney(v)
    v = tonumber(v) or 0
    return math.floor(v + 0.5)
end

function MechanicShared.GetSection(key)
    return MechanicShared.Sections[key]
end

function MechanicShared.IsDifferent(a, b)
    return not tableEquals(a, b)
end

function MechanicShared.GetCurrency(value)
    local symbol = (Config and Config.CurrencySymbol) or '$'
    return (symbol .. tostring(addMoney(value)))
end

function MechanicShared.CalculateLine(sectionKey, fromValue, toValue)
    local section = MechanicShared.Sections[sectionKey]
    if not section then return nil end
    if not MechanicShared.IsDifferent(fromValue, toValue) then return nil end

    local price = 0
    local labor = 0

    if section.priceKind == 'performance' then
        local idx = tonumber(toValue) or 0
        price = ((Config.Prices.performance[section.priceKey] or {})[idx] or 0)
    elseif section.priceKind == 'performanceToggle' then
        if section.priceKey == 'turbo' then
            price = toValue and (Config.Prices.performance.turbo.install or 0) or (Config.Prices.performance.turbo.remove or 0)
        end
    elseif section.priceKind == 'service' then
        if toValue then
            price = Config.Prices.service[section.priceKey] or 0
        end
    elseif section.priceKind == 'flat' then
        local base = Config.Prices.cosmetic[section.priceKey] or 0
        if section.mode == 'extras' and type(toValue) == 'table' and type(fromValue) == 'table' then
            local changed = 0
            for k, v in pairs(toValue) do
                if fromValue[k] ~= v then changed = changed + 1 end
            end
            price = base * changed
        else
            price = base
        end
    end

    if section.laborKind == 'performance' and price > 0 then labor = Config.Prices.labor.performance or 0 end
    if section.laborKind == 'visual' and price > 0 then labor = Config.Prices.labor.visual or 0 end
    if section.laborKind == 'paint' and price > 0 then labor = Config.Prices.labor.paint or 0 end
    if section.laborKind == 'service' and price > 0 then labor = Config.Prices.labor.service or 0 end

    return {
        key = section.key,
        label = section.label,
        icon = section.icon,
        description = section.description,
        price = addMoney(price),
        labor = addMoney(labor),
        total = addMoney(price + labor),
    }
end

function MechanicShared.BuildQuote(originalState, currentState, laborMultiplier)
    laborMultiplier = laborMultiplier or 1.0

    local lines = {}
    local subtotal = 0
    local labor = 0
    local baseLabor = Config.Prices.labor.base or 0

    for key, section in pairs(MechanicShared.Sections) do
        local fromValue = originalState[key]
        local toValue = currentState[key]
        local line = MechanicShared.CalculateLine(key, fromValue, toValue)

        if line and line.total > 0 then
            line.labor = addMoney((line.labor or 0) * laborMultiplier)
            line.total = addMoney((line.price or 0) + (line.labor or 0))
            subtotal = subtotal + (line.price or 0)
            labor = labor + (line.labor or 0)
            lines[#lines + 1] = line
        end
    end

    table.sort(lines, function(a, b)
        return a.label < b.label
    end)

    if #lines > 0 and baseLabor > 0 then
        labor = labor + baseLabor
    end

    return {
        lines = lines,
        subtotal = addMoney(subtotal),
        labor = addMoney(labor),
        total = addMoney(subtotal + labor),
    }
end
