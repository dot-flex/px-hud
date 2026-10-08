function masked1337.GetLocale()
    local result = {}
    for key, value in pairs(masked1337.Locales.en) do result[key] = value end
    for key, value in pairs(masked1337.Locales[masked1337.Config.Locale] or {}) do
        if type(value) == 'string' then result[key] = value end
    end
    return result
end

function masked1337.Translate(key)
    local selected = masked1337.Locales[masked1337.Config.Locale] or {}
    return selected[key] or masked1337.Locales.en[key] or key
end
