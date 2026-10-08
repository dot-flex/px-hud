local loaded = masked1337.Framework.loaded
local hidden, seatbelt, radioTalking = false, false, false
local activeVehicle, prompts, promptOwner = 0, nil, nil
local visible = false
local editingHud = false
local suppressors = {}
local location = { zone = '', street = '', crossing = '' }
local lastState
local interval = math.max(50, tonumber(masked1337.Config.UpdateInterval) or 100)
local components = { 6, 7, 8, 9 }
local vehicleCache, vehicleSampleAt = {}, 0

local function same(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    for key, value in pairs(a) do if not same(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function round(value, precision)
    return math.floor(value * precision + 0.5) / precision
end

local function clamp(value)
    return math.max(0, math.min(100, tonumber(value) or 0))
end

local function setVisible(value) hidden = not value end
exports('SetVisible', setVisible)
exports('SetSuppressed', function(value)
    local owner = GetInvokingResource()
    if owner then suppressors[owner] = value == true or nil end
end)
RegisterNetEvent('masked1337:hud:setVisible', setVisible)
RegisterCommand('hud', function() hidden = not hidden end, false)
RegisterCommand('hudreload', function() masked1337.Radar.requestRefresh(true); masked1337.Needs.refresh(); lastState = nil end, false)

local function setPrompts(items, owner)
    if type(items) ~= 'table' then prompts, promptOwner = nil, nil return end
    prompts = {}
    for i = 1, math.min(#items, 8) do
        local item = items[i]
        if type(item) == 'table' then
            prompts[#prompts + 1] = {
                key = tostring(item.key or ''):sub(1, 12),
                keyboard = item.keyboard and tostring(item.keyboard):sub(1, 12) or nil,
                label = tostring(item.labelKey and masked1337.Translate(item.labelKey) or item.label or ''):sub(1, 40)
            }
        end
    end
    promptOwner = owner
end
exports('SetPrompts', function(items) setPrompts(items, GetInvokingResource()) end)
exports('ClearPrompts', function()
    local owner = GetInvokingResource()
    if not promptOwner or promptOwner == owner then setPrompts(nil) end
end)
exports('SetFishing', function(enabled)
    setPrompts(enabled and masked1337.Config.FishingPrompts or nil, GetInvokingResource())
end)
AddEventHandler('onClientResourceStop', function(resource)
    suppressors[resource] = nil
    if resource == promptOwner then setPrompts(nil) end
end)

AddEventHandler('masked1337:hud:loaded', function(value)
    loaded = value
    if not loaded then
        seatbelt = false
        setPrompts(nil)
    end
end)
AddEventHandler('pma-voice:radioActive', function(active) radioTalking = active == true end)

local function getSavedHudPositions()
    local saved = GetResourceKvpString('masked1337:hud:positions')
    if not saved or saved == '' then return nil end
    local ok, result = pcall(json.decode, saved)
    return ok and type(result) == 'table' and result or nil
end

local initialPositions = getSavedHudPositions()
masked1337.Radar.setPosition(initialPositions and initialPositions.minimap)

RegisterNUICallback('masked1337:ready', function(_, cb)
    lastState = nil
    cb({
        unit = masked1337.Config.SpeedUnit,
        locale = masked1337.Config.Locale,
        translations = masked1337.GetLocale(),
        build = masked1337.Config.ShowBuildLabel and masked1337.Config.BuildLabel or '',
        positions = getSavedHudPositions()
    })
    if masked1337.Radar.layout then SendNUIMessage({ type = 'masked1337:layout', data = masked1337.Radar.layout }) end
end)

local function openHudSettings()
    editingHud = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'masked1337:openSettings', positions = getSavedHudPositions() })
end

RegisterCommand('hudedit', openHudSettings, false)
RegisterCommand('cinematic', function()
    SendNUIMessage({ type = 'masked1337:toggleCinematic' })
end, false)

RegisterNUICallback('masked1337:closeSettings', function(_, cb)
    editingHud = false
    local saved = getSavedHudPositions()
    masked1337.Radar.setPosition(saved and saved.minimap)
    masked1337.Radar.requestRefresh()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('masked1337:savePositions', function(data, cb)
    local positions = {}
    if type(data) == 'table' then
        for _, key in ipairs({ 'vitals', 'vehicle', 'minimap' }) do
            local item = data[key]
            if type(item) == 'table' then
                local left, top = tonumber(item.left), tonumber(item.top)
                positions[key] = {
                    left = left and clamp(left) or nil,
                    top = top and clamp(top) or nil,
                    scale = math.max(0.65, math.min(2.0, tonumber(item.scale) or 1.0))
                }
            end
        end
    end
    editingHud = false
    masked1337.Radar.setPosition(positions.minimap)
    masked1337.Radar.requestRefresh()
    SetResourceKvp('masked1337:hud:positions', json.encode(positions))
    SendNUIMessage({ type = 'masked1337:setPositions', positions = positions })
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('masked1337:previewMinimap', function(data, cb)
    if editingHud then masked1337.Radar.setPosition(data, true) end
    cb({ layout = masked1337.Radar.layout })
end)

local function driverVehicle()
    if not loaded or hidden or next(suppressors) or IsPauseMenuActive() then return 0 end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and vehicle or 0
end

if masked1337.Config.Vehicle.controls then
    RegisterCommand('hudengine', function()
        local vehicle = driverVehicle()
        if vehicle == 0 then return end
        SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
    end, false)
    RegisterKeyMapping('hudengine', masked1337.Translate('key_engine'), 'keyboard', masked1337.Config.Vehicle.engineKey)
    RegisterCommand('hudlock', function()
        local vehicle = driverVehicle()
        if vehicle == 0 then return end
        if masked1337.Config.Vehicle.lockEvent then TriggerEvent(masked1337.Config.Vehicle.lockEvent, vehicle) return end
        if not NetworkHasControlOfEntity(vehicle) then return end
        local locked = GetVehicleDoorLockStatus(vehicle) >= 2
        SetVehicleDoorsLocked(vehicle, locked and 1 or 2)
        PlaySoundFromEntity(-1, 'Remote_Control_Fob', vehicle, 'PI_Menu_Sounds', true, 0)
    end, false)
    RegisterKeyMapping('hudlock', masked1337.Translate('key_lock'), 'keyboard', masked1337.Config.Vehicle.lockKey)
    RegisterCommand('hudseatbelt', function()
        if not loaded or hidden or next(suppressors) or IsPauseMenuActive() then return end
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then return end
        local class = GetVehicleClass(vehicle)
        if class == 8 or class == 13 or class == 14 or class == 15 or class == 16 then return end
        seatbelt = not seatbelt
        TriggerEvent('masked1337:hud:seatbeltChanged', seatbelt)
    end, false)
    RegisterKeyMapping('hudseatbelt', masked1337.Translate('key_seatbelt'), 'keyboard', masked1337.Config.Vehicle.seatbeltKey)
end

CreateThread(function()
    local previousCoords, streetHash, crossingHash, zoneCode
    while true do
        if loaded and visible then
            local coords = GetEntityCoords(PlayerPedId())
            if not previousCoords or #(coords - previousCoords) > 2.0 then
                previousCoords = coords
                local street, crossing = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local code = GetNameOfZone(coords.x, coords.y, coords.z)
                if street ~= streetHash or crossing ~= crossingHash or code ~= zoneCode then
                    streetHash, crossingHash, zoneCode = street, crossing, code
                    local zone = GetLabelText(code)
                    location = {
                        zone = zone ~= 'NULL' and zone or code,
                        street = GetStreetNameFromHashKey(street),
                        crossing = crossing ~= 0 and GetStreetNameFromHashKey(crossing) or ''
                    }
                end
            end
        elseif not loaded then
            previousCoords, streetHash, crossingHash, zoneCode = nil, nil, nil, nil
        end
        Wait(750)
    end
end)

CreateThread(function()
    while true do
        local ped = loaded and PlayerPedId() or 0
        local vehicle = loaded and GetVehiclePedIsIn(ped, false) or 0
        local dead = loaded and IsEntityDead(ped)
        if vehicle ~= activeVehicle then
            vehicleCache, vehicleSampleAt = {}, 0
        end
        if vehicle ~= activeVehicle or dead then
            seatbelt = false
            activeVehicle = vehicle
        end
        visible = loaded and not hidden and next(suppressors) == nil
            and not (masked1337.Config.HideInPause and IsPauseMenuActive())
            and not (masked1337.Config.HideInCutscene and IsCutsceneActive())
            and not IsScreenFadedOut()
        local data = { visible = visible }
        if visible then
            local maxHealth = math.max(1, GetEntityMaxHealth(ped) - 100)
            data.health = dead and 0 or round(clamp((GetEntityHealth(ped) - 100) / maxHealth * 100), 10)
            data.armor = clamp(GetPedArmour(ped))
            data.hunger = masked1337.Needs.hunger and round(masked1337.Needs.hunger, 10)
            data.thirst = masked1337.Needs.thirst and round(masked1337.Needs.thirst, 10)
            data.stress = masked1337.Needs.stress and round(masked1337.Needs.stress, 10)
            data.stamina = round(clamp(100 - GetPlayerSprintStaminaRemaining(PlayerId())), 10)

            data.oxygen = IsPedSwimmingUnderWater(ped)
                and round(clamp(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10), 10) or 0
            local proximity = LocalPlayer.state.proximity
            data.voiceMode = type(proximity) == 'table' and tonumber(proximity.index) or 2
            data.talking = NetworkIsPlayerTalking(PlayerId()) or MumbleIsPlayerTalking(PlayerId()) or radioTalking
            data.radio = radioTalking

            data.heading = round((360 - GetGameplayCamRot(2).z) % 360, 4)
            data.location = location
            data.radar = masked1337.Radar.ready and (editingHud or masked1337.Config.ShowOnFoot or vehicle ~= 0)
            data.waypoint = data.radar and masked1337.Waypoint.read(ped) or false
            data.postal = data.radar and masked1337.Postal.current or false
            data.controller = not IsUsingKeyboard(0)
            data.prompts = prompts or false
            data.vehicle = false
            if vehicle ~= 0 and masked1337.Config.Vehicle.enabled then
                local now = GetGameTimer()
                if now >= vehicleSampleAt then
                    vehicleSampleAt = now + 500
                    local _, lights, highbeams = GetVehicleLightsState(vehicle)
                    local fuel = masked1337.Vehicle.getFuel(vehicle)
                    local class = vehicleCache.class or GetVehicleClass(vehicle)
                    vehicleCache = {
                        fuel = fuel and round(fuel, 10) or false,
                        class = class,
                        engineWarning = class ~= 13 and GetVehicleEngineHealth(vehicle) < 650,
                        lights = lights == true or lights == 1 or highbeams == true or highbeams == 1,
                        locked = GetVehicleDoorLockStatus(vehicle) >= 2
                    }
                end
                local speed = GetEntitySpeed(vehicle)
                local reverse = GetEntitySpeedVector(vehicle, true).y < -0.5
                local engine = GetIsVehicleEngineRunning(vehicle)
                local class = vehicleCache.class
                local hasBelt = class ~= 8 and class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16
                data.vehicle = {
                    speed = math.floor(speed * (masked1337.Config.SpeedUnit == 'kmh' and 3.6 or 2.236936) + 0.5),
                    rpm = engine and round(GetVehicleCurrentRpm(vehicle), 100) or 0,
                    gear = masked1337.Vehicle.getGear(vehicle, speed, reverse),
                    fuel = vehicleCache.fuel, hasFuel = class ~= 13,
                    lights = vehicleCache.lights,
                    locked = vehicleCache.locked,
                    engineWarning = vehicleCache.engineWarning,
                    seatbelt = seatbelt, hasBelt = hasBelt
                }
            end
        end
        if not same(data, lastState) then
            SendNUIMessage({ type = 'masked1337:state', data = data })
            lastState = data
        end
        Wait(visible and interval or 250)
    end
end)

CreateThread(function()
    while true do
        if loaded then
            local showRadar = visible and next(suppressors) == nil and not IsPauseMenuActive()
                and masked1337.Radar.ready and (editingHud or masked1337.Config.ShowOnFoot or activeVehicle ~= 0)
            masked1337.Radar.setVisible(showRadar)
            if showRadar then masked1337.Radar.draw() end
            for i = 1, #components do HideHudComponentThisFrame(components[i]) end
            if seatbelt then
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
            end
            Wait(0)
        else
            masked1337.Radar.setVisible(false)
            Wait(250)
        end
    end
end)

local displayPending, stopping = false, false
AddEventHandler('esx_status:setDisplay', function(value)
    if masked1337.Framework.kind ~= 'esx' or stopping or displayPending or not masked1337.Config.HideEsxStatus or (tonumber(value) or 0) <= 0 then return end
    displayPending = true
    SetTimeout(0, function()
        displayPending = false
        if not stopping then TriggerEvent('esx_status:setDisplay', 0.0) end
    end)
end)

CreateThread(function()
    local statusHidden = false
    while true do
        local started = masked1337.Framework.kind == 'esx' and GetResourceState('esx_status') == 'started'
        if masked1337.Config.HideEsxStatus and started and not statusHidden then
            TriggerEvent('esx_status:setDisplay', 0.0)
        end
        statusHidden = started and masked1337.Config.HideEsxStatus
        Wait(2000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
    if resource == GetCurrentResourceName() and masked1337.Framework.kind == 'esx' and masked1337.Config.HideEsxStatus then
        stopping = true
        TriggerEvent('esx_status:setDisplay', 1.0)
    end
end)
