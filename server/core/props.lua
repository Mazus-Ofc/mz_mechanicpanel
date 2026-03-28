function MZMP.SanitizeColorArray(value)
    local t = type(value) == 'table' and value or {}
    return {
        math.floor(MZMP.Clamp(t[1] or t.r or 255, 0, 255)),
        math.floor(MZMP.Clamp(t[2] or t.g or 255, 0, 255)),
        math.floor(MZMP.Clamp(t[3] or t.b or 255, 0, 255)),
    }
end

function MZMP.SanitizeNeonEnabled(value)
    local t = type(value) == 'table' and value or {}
    return {
        t[1] == true or t.left == true,
        t[2] == true or t.right == true,
        t[3] == true or t.front == true,
        t[4] == true or t.back == true,
    }
end

function MZMP.SanitizeExtras(value)
    local clean = {}
    if type(value) ~= 'table' then return clean end

    for extraId, enabled in pairs(value) do
        local key = tostring(tonumber(extraId) or extraId)
        clean[key] = enabled == true
    end

    return clean
end

function MZMP.SanitizePropValue(key, value)
    if key == 'engineHealth' or key == 'bodyHealth' or key == 'tankHealth' then
        return MZMP.Clamp(value, 0, 1000.0)
    end

    if key == 'dirtLevel' then
        return MZMP.Clamp(value, 0, 15.0)
    end

    if key == 'customPrimaryColor' or key == 'customSecondaryColor' or key == 'tyreSmokeColor' or key == 'neonColor' then
        return MZMP.SanitizeColorArray(value)
    end

    if key == 'neonEnabled' then
        return MZMP.SanitizeNeonEnabled(value)
    end

    if key == 'extras' then
        return MZMP.SanitizeExtras(value)
    end

    if key == 'plateIndex' then
        return math.floor(MZMP.Clamp(value, 0, 5))
    end

    if key == 'windowTint' then
        return math.floor(MZMP.Clamp(value, -1, 6))
    end

    if key == 'xenonColor' then
        return math.floor(MZMP.Clamp(value, -1, 255))
    end

    if key == 'color1' or key == 'color2' or key == 'pearlescentColor' or key == 'wheelColor' or key == 'wheels' then
        return math.floor(MZMP.Clamp(value, -1, 255))
    end

    if key == 'modTurbo' or key == 'modXenon' or key == 'modBulletproofTires' or key == 'modSmokeEnabled' or key == 'modCustomTiresF' or key == 'modCustomTiresR' then
        return value == true
    end

    if key:sub(1, 3) == 'mod' then
        return math.floor(MZMP.Clamp(value, -1, 255))
    end

    return value
end

function MZMP.MergeProps(baseProps, incomingProps, propKeys)
    local result = MZMP.DeepCopy(baseProps or {})
    local incoming = type(incomingProps) == 'table' and incomingProps or {}

    for propKey in pairs(propKeys or {}) do
        if incoming[propKey] ~= nil then
            result[propKey] = MZMP.SanitizePropValue(propKey, incoming[propKey])
        end
    end

    return result
end

function MZMP.BuildTouchedPropKeys(originalState, currentState)
    local touched = {}

    originalState = originalState or {}
    currentState = currentState or {}

    for stateKey, propList in pairs(MZMP.StateToPropKeys) do
        local originalValue = originalState[stateKey]
        local currentValue = currentState[stateKey]

        if MechanicShared.IsDifferent(originalValue, currentValue) then
            for _, propKey in ipairs(propList) do
                touched[propKey] = true
            end
        end
    end

    return touched
end

function MZMP.NormalizeOriginalProps(props)
    local allowed = {}
    for _, propList in pairs(MZMP.StateToPropKeys) do
        for _, propKey in ipairs(propList) do
            allowed[propKey] = true
        end
    end

    allowed.engineHealth = true
    allowed.bodyHealth = true
    allowed.tankHealth = true
    allowed.dirtLevel = true

    return MZMP.MergeProps({}, props or {}, allowed)
end

function MZMP.BuildFinalProps(session, clientProps, existingDbProps)
    local touchedKeys = MZMP.BuildTouchedPropKeys(session.originalState, session.currentState)
    local baseProps = MZMP.MergeProps(existingDbProps or {}, session.originalProps or {}, touchedKeys)
    local finalProps = MZMP.MergeProps(baseProps, clientProps or {}, touchedKeys)

    local currentState = session.currentState or {}

    if currentState.service_full then
        finalProps.engineHealth = 1000.0
        finalProps.bodyHealth = 1000.0
        finalProps.tankHealth = 1000.0
        finalProps.dirtLevel = 0.0
    else
        if currentState.service_engine then
            finalProps.engineHealth = 1000.0
        end

        if currentState.service_body then
            finalProps.bodyHealth = 1000.0
        end

        if currentState.service_clean then
            finalProps.dirtLevel = 0.0
        end
    end

    return finalProps
end
