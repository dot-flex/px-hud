masked1337.Radar = { ready = false, layout = nil, generation = 0 }
local customPosition
local scaleform, scaleformReady, textureReady, originalNorthAlpha
local originalRadarHidden = IsRadarHidden()
local refreshRequested = true
local oldW, oldH, oldSafe, wasPaused = 0, 0, 0, false
local textureRetryAt, scaleformRetryAt = 0, 0
local textureWarning, scaleformWarning = false, false
local radarShown, radarGeneration, warmupFrames, expanded

local function prepareTextures()
    if textureReady then return end
    RequestStreamedTextureDict('gta6_graphics', false)
    local deadline = GetGameTimer() + 5000
    while not HasStreamedTextureDictLoaded('gta6_graphics') and GetGameTimer() < deadline do
        Wait(50)
    end
    if not HasStreamedTextureDictLoaded('gta6_graphics') then
        if not textureWarning then
            print('[masked1337] gta6_graphics is not loaded yet; using the native mask and retrying.')
            textureWarning = true
        end
        textureRetryAt = GetGameTimer() + 5000
        return
    end
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'gta6_graphics', 'radarmasksm')
    textureReady = true
    refreshRequested = true
end

local function prepareScaleform()
    if scaleformReady then return end
    scaleform = scaleform or RequestScaleformMovie('minimap')
    local deadline = GetGameTimer() + 5000
    while not HasScaleformMovieLoaded(scaleform) and GetGameTimer() < deadline do Wait(50) end
    scaleformReady = HasScaleformMovieLoaded(scaleform)
    if not scaleformReady then
        if not scaleformWarning then
            print('[masked1337] Waiting for the streamed minimap scaleform; retrying.')
            scaleformWarning = true
        end
        scaleformRetryAt = GetGameTimer() + 5000
    end
end

local function hideSatnav()
    if not scaleformReady then return end
    BeginScaleformMovieMethod(scaleform, 'HIDE_SATNAV')
    EndScaleformMovieMethod()
end

function masked1337.Radar.configure(w, h, safeSize, preview)
    if not w then w, h = GetActiveScreenResolution() end
    if w <= 0 or h <= 0 or IsPauseMenuActive() then return false end
    local scale = h / 1080
    local left = masked1337.Config.Minimap.left * scale / w
    local bottom = 1.0 - masked1337.Config.Minimap.bottom * scale / h
    local screenWidth = masked1337.Config.Minimap.width * scale / w
    local screenHeight = masked1337.Config.Minimap.height * scale / h

    if customPosition then
        left = math.max(0.0, math.min(1.0 - screenWidth, customPosition.left / 100))
        bottom = math.max(0.0, math.min(1.0 - screenHeight, customPosition.top / 100)) + screenHeight
    end

    SetScriptGfxAlign(string.byte('L'), string.byte('B'))
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
    local ox, oy = GetScriptGfxPosition(0.0, 0.0)
    local ex, ey = GetScriptGfxPosition(1.0, 1.0)
    ResetScriptGfxAlign()
    local sx, sy = ex - ox, ey - oy
    if math.abs(sx) < 0.001 or math.abs(sy) < 0.001 then return false end
    local x, y = (left - ox) / sx, (bottom - oy) / sy
    local width, height = screenWidth / sx, screenHeight / sy
    local dx, dy = x - (-0.0045), y - 0.002
    SetMinimapClipType(0)
    SetMinimapComponentPosition('minimap', 'L', 'B', x, y, width, height)

    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020 + dx, 0.032 + dy, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03 + dx, 0.022 + dy, 0.266, 0.237)
    masked1337.Radar.layout = {
        x = left, y = bottom - screenHeight, width = screenWidth, height = screenHeight,
        frameInsets = masked1337.Config.Minimap.frameInsets,
        safe = (1.0 - (safeSize or GetSafeZoneSize())) * 0.5
    }
    if not preview then
        SendNUIMessage({ type = 'masked1337:layout', data = masked1337.Radar.layout })
        SetRadarZoom(masked1337.Config.Minimap.zoom)
        hideSatnav()
    end
    return true
end

function masked1337.Radar.setPosition(position, preview)
    customPosition = nil
    if type(position) == 'table' then
        local left, top = tonumber(position.left), tonumber(position.top)
        if left and top and left == left and top == top then
            customPosition = { left = math.max(0, math.min(100, left)), top = math.max(0, math.min(100, top)) }
        end
    end
    if not masked1337.Radar.configure(nil, nil, nil, preview) then refreshRequested = true end
end

function masked1337.Radar.requestRefresh()
    refreshRequested = true
end

function masked1337.Radar.setVisible(wanted)
    local paused = IsPauseMenuActive()
    wanted = wanted == true and masked1337.Radar.ready and not paused
    if not wanted then
        warmupFrames = nil
        if radarShown ~= false then DisplayRadar(false); radarShown = false end
        if expanded and not paused then
            SetBigmapActive(false, false)
            expanded = false
        end
        return
    end
    if radarShown ~= true or radarGeneration ~= masked1337.Radar.generation then
        if expanded then SetBigmapActive(false, false); expanded = false end
        DisplayRadar(true)
        radarShown = true
        radarGeneration = masked1337.Radar.generation
        warmupFrames = 4
        return
    end
    if warmupFrames then
        warmupFrames = warmupFrames - 1
        if warmupFrames == 2 then
            SetBigmapActive(true, false)
            expanded = true
        elseif warmupFrames == 0 then
            SetBigmapActive(false, false)
            SetRadarZoom(masked1337.Config.Minimap.zoom)
            expanded, warmupFrames = false, nil
        end
    end
end

function masked1337.Radar.draw()
    if not masked1337.Radar.ready or not scaleformReady then return end
    hideSatnav()
    BeginScaleformMovieMethod(scaleform, 'SETUP_HEALTH_ARMOUR')
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(100) end
    local north = GetNorthRadarBlip()
    if north ~= 0 and DoesBlipExist(north) then
        originalNorthAlpha = GetBlipAlpha(north)
        SetBlipAlpha(north, 0)
    end
    while true do
        local now = GetGameTimer()
        if not IsPauseMenuActive() then
            if not textureReady and now >= textureRetryAt then prepareTextures() end
            if not scaleformReady and now >= scaleformRetryAt then prepareScaleform() end
        end
        local w, h = GetActiveScreenResolution()
        local safe, paused = GetSafeZoneSize(), IsPauseMenuActive()
        local resized = w ~= oldW or h ~= oldH or safe ~= oldSafe
        if not paused and (refreshRequested or wasPaused or resized) then
            if masked1337.Radar.configure(w, h, safe) then
                oldW, oldH, oldSafe = w, h, safe
                refreshRequested = false
                masked1337.Radar.ready = true
                masked1337.Radar.generation = masked1337.Radar.generation + 1
            end
        end
        wasPaused = paused
        Wait(250)
    end
end)

AddEventHandler('masked1337:hud:loaded', function(loaded) if loaded then masked1337.Radar.requestRefresh() end end)
AddEventHandler('playerSpawned', function() masked1337.Radar.requestRefresh() end)
AddEventHandler('esx:onPlayerSpawn', function() masked1337.Radar.requestRefresh() end)
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'map-postalmap' or resource == 'gta6_atlasmap' then masked1337.Radar.requestRefresh(true) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    masked1337.Radar.ready = false
    if not IsPauseMenuActive() then SetBigmapActive(false, false) end
    if textureReady then RemoveReplaceTexture('platform:/textures/graphics', 'radarmasksm') end
    SetStreamedTextureDictAsNoLongerNeeded('gta6_graphics')
    SetMinimapClipType(0)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.032, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
    local north = GetNorthRadarBlip()
    if north ~= 0 and DoesBlipExist(north) then SetBlipAlpha(north, originalNorthAlpha or 255) end
    if not IsPauseMenuActive() then SetRadarZoom(1100) end
    if scaleformReady then
        BeginScaleformMovieMethod(scaleform, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(0)
        EndScaleformMovieMethod()
    end
    if scaleform then SetScaleformMovieAsNoLongerNeeded(scaleform) end
    DisplayRadar(not originalRadarHidden)
end)
