masked1337.Waypoint = {}
local nextSample, cached = 0, false

function masked1337.Waypoint.read(ped)
    local now = GetGameTimer()
    if now < nextSample then return cached end
    nextSample = now + 250
    local blip = GetFirstBlipInfoId(8)
    if blip == 0 or not DoesBlipExist(blip) then
        cached = false
        return cached
    end
    local destination = GetBlipInfoIdCoord(blip)
    local origin = GetEntityCoords(ped)
    local dx, dy = destination.x - origin.x, destination.y - origin.y
    cached = {
        bearing = math.floor((math.deg(math.atan(dx, dy)) % 360) * 4 + 0.5) / 4,
        distance = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
    }
    return cached
end
