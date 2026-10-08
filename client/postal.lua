masked1337.Postal = { current = false }
local points, external = {}, false

exports('SetPostal', function(code, distance)
    distance = tonumber(distance)
    external = code ~= nil and distance ~= nil and distance == distance
    masked1337.Postal.current = external and { code = tostring(code), distance = math.max(0, distance) } or false
end)

local function loadPostals()
    points = {}
    local raw = LoadResourceFile(masked1337.Config.Postal.resource, masked1337.Config.Postal.file)
    if not raw then return end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return end
    for _, entry in pairs(data) do
        if type(entry) == 'table' then
            local x, y = tonumber(entry.x), tonumber(entry.y)
            local code = entry.code or entry.postal
            if x and y and code then points[#points + 1] = { x = x, y = y, code = tostring(code) } end
        end
    end
end

AddEventHandler('onClientResourceStart', function(resource)
    if resource == masked1337.Config.Postal.resource then loadPostals() end
end)
CreateThread(function()
    loadPostals()
    while true do
        if not external and #points > 0 then
            local coords = GetEntityCoords(PlayerPedId())
            local closest, best
            for _, point in ipairs(points) do
                local distance = (coords.x - point.x)^2 + (coords.y - point.y)^2
                if not best or distance < best then closest, best = point, distance end
            end
            masked1337.Postal.current = { code = closest.code, distance = math.floor(math.sqrt(best) * 10 + 0.5) / 10 }
        end
        Wait(1000)
    end
end)
