masked1337 = masked1337 or {}
masked1337.Framework = {}

function masked1337.Percent(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return math.max(0, math.min(100, value))
end

function masked1337.Framework.detect()
    local selected = masked1337.Config.Framework
    local resources = { qbox = 'qbx_core', qbcore = 'qb-core', esx = 'es_extended' }
    if selected ~= 'auto' then
        local resource = resources[selected]
        return resource and GetResourceState(resource) == 'started' and selected or nil
    end
    for _, name in ipairs({ 'qbox', 'qbcore', 'esx' }) do
        if GetResourceState(resources[name]) == 'started' then return name end
    end
end
