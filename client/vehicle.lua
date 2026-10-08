masked1337.Vehicle = {}
function masked1337.Vehicle.getGear(vehicle, speedMetres, reversing)
    if reversing and speedMetres > 0.5 then return 'R' end
    if speedMetres < 0.25 then return '1' end
    return tostring(math.max(1, GetVehicleCurrentGear(vehicle)))
end

local function percent(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then return nil end
    return math.max(0, math.min(100, number))
end

function masked1337.Vehicle.getFuel(vehicle)
    if masked1337.Config.Vehicle.getFuel then
        local ok, value = pcall(masked1337.Config.Vehicle.getFuel, vehicle)
        if ok and percent(value) ~= nil then return percent(value) end
    end

    if GetResourceState('ox_fuel') == 'started' then
        local value = percent(Entity(vehicle).state.fuel)
        if value ~= nil then return value end
    end
    return percent(GetVehicleFuelLevel(vehicle))
end
