CreateThread(function()
    local lastShot = -1000
    while true do
        if masked1337.Framework.loaded and masked1337.Config.Stress.enabled then
            local now, ped = GetGameTimer(), PlayerPedId()
            if not IsEntityDead(ped) and not IsPauseMenuActive() and IsPedShooting(ped) and now - lastShot >= 1000 then
                lastShot = now
                TriggerServerEvent('masked1337:hud:shot')
            end
            Wait(100)
        else
            Wait(1000)
        end
    end
end)
exports('GetStress', function() return masked1337.Needs.stress end)
