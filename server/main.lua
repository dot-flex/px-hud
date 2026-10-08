local bridge = masked1337.Framework
local sessions, requests = {}, {}

local function session(source)
    source = tonumber(source)
    if not source or source < 1 then return end
    local player, kind = bridge.player(source)
    if not player then sessions[source] = nil; return end
    local identity = bridge.identity(player, kind)
    if not identity then return end
    local current = sessions[source]
    if not current or current.identity ~= identity or current.kind ~= kind then
        current = {
            identity = identity, kind = kind,
            stress = bridge.loadStress(player, kind, identity),
            lastShot = -1000, active = false,
            nextInterval = GetGameTimer() + masked1337.Config.Stress.interval
        }
        sessions[source] = current
    elseif kind ~= 'esx' then
        current.stress = bridge.needs(player, kind).stress or current.stress
    end
    return current, player, source
end

local function publish(source, current, player)
    local needs = bridge.needs(player, current.kind)
    needs.stress = current.stress
    TriggerClientEvent('masked1337:hud:snapshot', source, {
        loaded = true, framework = current.kind, needs = needs
    })
end

local function setStress(source, amount, absolute)
    amount = tonumber(amount)
    if not amount or amount ~= amount or math.abs(amount) == math.huge then return false end
    local current, player, id = session(source)
    if not current then return false end
    local value = masked1337.Percent(absolute and amount or current.stress + amount)
    if value ~= current.stress then
        current.stress = value
        bridge.saveStress(id, player, current.kind, current.identity, value)
        publish(id, current, player)
    end
    return true
end

RegisterNetEvent('masked1337:hud:requestSnapshot', function()
    local id, now = source, GetGameTimer()
    if requests[id] and now - requests[id] < 1000 then return end
    requests[id] = now
    local current, player = session(id)
    if current then publish(id, current, player)
    else TriggerClientEvent('masked1337:hud:snapshot', id, { loaded = false }) end
end)

RegisterNetEvent('masked1337:hud:shot', function()
    if not masked1337.Config.Stress.enabled then return end
    local current = session(source)
    if not current then return end
    local now, ped = GetGameTimer(), GetPlayerPed(source)
    if ped == 0 or GetEntityHealth(ped) <= 0 or now - current.lastShot < 1000 then return end
    current.lastShot, current.active = now, true
    setStress(source, masked1337.Config.Stress.shootingGain)
end)

exports('AddStress', function(source, amount)
    amount = masked1337.Percent(amount)
    return amount and setStress(source, amount) or false
end)
exports('RelieveStress', function(source, amount)
    amount = masked1337.Percent(amount)
    return amount and setStress(source, -amount) or false
end)
exports('SetStress', function(source, amount) return setStress(source, amount, true) end)
exports('GetStress', function(source)
    local current = session(source)
    return current and current.stress or nil
end)
exports('Notify', function(source, data)
    if not bridge.player(source) then return false end
    TriggerClientEvent('masked1337:hud:notify', source, data)
    return true
end)

CreateThread(function()
    while true do
        local now = GetGameTimer()
        for id in pairs(sessions) do
            local current = session(id)
            if current then
                local ped = GetPlayerPed(id)
                if not masked1337.Config.Stress.enabled or ped == 0 or GetEntityHealth(ped) <= 0 then
                    current.nextInterval, current.active = now + masked1337.Config.Stress.interval, false
                else
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local speeding = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
                        and GetEntitySpeed(vehicle) * 3.6 >= masked1337.Config.Stress.speedThreshold
                    if now >= current.nextInterval then
                        if speeding then setStress(id, masked1337.Config.Stress.drivingGain)
                        elseif not current.active then setStress(id, -masked1337.Config.Stress.calmRelief) end
                        current.nextInterval, current.active = now + masked1337.Config.Stress.interval, false
                    elseif speeding then current.active = true end
                end
            end
        end
        Wait(1000)
    end
end)

AddEventHandler('playerDropped', function()
    sessions[source], requests[source] = nil, nil
end)
