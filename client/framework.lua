masked1337.Framework.loaded = false
masked1337.Framework.kind = nil
masked1337.Framework.needs = {}

RegisterNetEvent('masked1337:hud:snapshot', function(data)
    if type(data) ~= 'table' then return end
    local wasLoaded = masked1337.Framework.loaded
    masked1337.Framework.loaded = data.loaded == true
    masked1337.Framework.kind = data.framework
    masked1337.Framework.needs = type(data.needs) == 'table' and data.needs or {}
    TriggerEvent('masked1337:hud:needsUpdated', masked1337.Framework.needs)
    if wasLoaded ~= masked1337.Framework.loaded then
        TriggerEvent('masked1337:hud:loaded', masked1337.Framework.loaded)
    end
end)

local function logout()
    masked1337.Framework.loaded = false
    masked1337.Framework.needs = {}
    TriggerEvent('masked1337:hud:needsUpdated', {})
    TriggerEvent('masked1337:hud:loaded', false)
end

RegisterNetEvent('esx:onPlayerLogout', logout)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', logout)
RegisterNetEvent('qbx_core:client:playerLoggedOut', logout)
for _, name in ipairs({ 'esx:playerLoaded', 'QBCore:Client:OnPlayerLoaded' }) do
    RegisterNetEvent(name, function() TriggerServerEvent('masked1337:hud:requestSnapshot') end)
end
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if masked1337.Framework.kind == 'esx' or type(data) ~= 'table' then return end
    local metadata = data.metadata or {}
    masked1337.Framework.needs = {
        hunger = masked1337.Percent(metadata.hunger),
        thirst = masked1337.Percent(metadata.thirst),
        stress = masked1337.Percent(metadata.stress)
    }
    TriggerEvent('masked1337:hud:needsUpdated', masked1337.Framework.needs)
end)
RegisterNetEvent('qbx_core:client:onSetMetaData', function(key, _, value)
    if key == 'hunger' or key == 'thirst' or key == 'stress' then
        masked1337.Framework.needs[key] = masked1337.Percent(value)
        TriggerEvent('masked1337:hud:needsUpdated', masked1337.Framework.needs)
    end
end)
AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'es_extended' or resource == 'qb-core' or resource == 'qbx_core' then logout() end
end)
CreateThread(function()
    while true do
        TriggerServerEvent('masked1337:hud:requestSnapshot')
        Wait(2000)
    end
end)
