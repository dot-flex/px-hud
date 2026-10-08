masked1337.Needs = { hunger = nil, thirst = nil, stress = nil }

function masked1337.Needs.refresh()
    if not masked1337.Framework.loaded then return end
    if masked1337.Framework.kind == 'esx' and GetResourceState('esx_status') == 'started' then
        for _, name in ipairs({ 'hunger', 'thirst' }) do
            TriggerEvent('esx_status:getStatus', name, function(status)
                local value = tonumber(status.percent)
                if type(status.getPercent) == 'function' then value = status.getPercent()
                elseif status.val then value = status.val / masked1337.Config.Needs.statusMax * 100 end
                masked1337.Needs[name] = masked1337.Percent(value)
            end)
        end
    end
end

AddEventHandler('masked1337:hud:needsUpdated', function(needs)
    for _, name in ipairs({ 'hunger', 'thirst', 'stress' }) do
        masked1337.Needs[name] = masked1337.Percent(needs[name])
    end
    masked1337.Needs.refresh()
end)
AddEventHandler('esx_status:onTick', function(statuses)
    if masked1337.Framework.kind ~= 'esx' or not masked1337.Framework.loaded then return end
    for _, status in pairs(statuses or {}) do
        if status.name == 'hunger' or status.name == 'thirst' then
            masked1337.Needs[status.name] = masked1337.Percent(status.percent)
        end
    end
end)
CreateThread(function()
    while true do
        masked1337.Needs.refresh()
        Wait(math.max(500, masked1337.Config.Needs.pollInterval))
    end
end)
