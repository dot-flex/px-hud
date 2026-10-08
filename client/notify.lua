local ready = false
local positions = {
    ['top'] = true, ['top-left'] = true, ['top-right'] = true,
    ['bottom'] = true, ['bottom-left'] = true, ['bottom-right'] = true,
    ['center-left'] = true, ['center-right'] = true
}

local function text(value, limit)
    if type(value) ~= 'string' and type(value) ~= 'number' then return '' end
    return tostring(value):sub(1, limit)
end

local function notify(data, kind, duration)
    if not ready then return false end
    if type(data) == 'string' then data = { description = data, type = kind, duration = duration } end
    if type(data) ~= 'table' then return false end
    local title, description = text(data.title, 240), text(data.description, 1600)
    if title == '' and description == '' then return false end
    local notificationType = data.type or data.status or 'info'
    if notificationType == 'inform' then notificationType = 'info' end
    if notificationType ~= 'success' and notificationType ~= 'error' and notificationType ~= 'warning' then notificationType = 'info' end
    local lifetime = tonumber(data.duration) or 5000
    if lifetime ~= lifetime then lifetime = 5000 end
    if lifetime ~= 0 then lifetime = math.max(100, math.min(60000, lifetime)) end
    local icon = type(data.icon) == 'table' and data.icon[2] or data.icon
    SendNUIMessage({ type = 'masked1337:notify', data = {
        id = data.id ~= nil and text(data.id, 128) or nil,
        title = title, description = description, type = notificationType,
        duration = lifetime, showDuration = data.showDuration == true,
        position = positions[data.position] and data.position or 'top-left',
        icon = text(icon, 64), iconColor = text(data.iconColor, 64)
    } })
    return true
end

exports('Notify', notify)
exports('IsNotificationReady', function() return ready end)
exports('DismissNotification', function(id)
    if ready then SendNUIMessage({ type = 'masked1337:notify:remove', id = text(id, 128) }) end
end)
RegisterNetEvent('masked1337:hud:notify', notify)
RegisterNUICallback('masked1337:notificationsReady', function(_, cb)
    ready = true
    cb({ ok = true })
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then ready = false end
end)
