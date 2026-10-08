local bridge = masked1337.Framework

function bridge.player(source)
    local kind = bridge.detect()
    if kind == 'esx' then
        return exports['es_extended']:getSharedObject().GetPlayerFromId(source), kind
    elseif kind == 'qbcore' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(source), kind
    elseif kind == 'qbox' then
        return exports['qbx_core']:GetPlayer(source), kind
    end
end

function bridge.identity(player, kind)
    if kind == 'esx' then return player.getIdentifier() end
    return player.PlayerData and player.PlayerData.citizenid
end

function bridge.needs(player, kind)
    if kind == 'esx' then
        local result = {}
        local statuses = player.get('status')
        if type(statuses) ~= 'table' then return result end
        for _, status in pairs(statuses) do
            if type(status) == 'table' and (status.name == 'hunger' or status.name == 'thirst' or status.name == 'stress') then
                result[status.name] = masked1337.Percent((tonumber(status.val) or 0) / masked1337.Config.Needs.statusMax * 100)
            end
        end
        return result
    end
    local metadata = player.PlayerData.metadata
    if type(metadata) ~= 'table' then metadata = {} end
    return {
        hunger = masked1337.Percent(metadata.hunger),
        thirst = masked1337.Percent(metadata.thirst),
        stress = masked1337.Percent(metadata.stress)
    }
end

function bridge.saveStress(source, player, kind, identity, value)
    if kind == 'qbox' then
        exports['qbx_core']:SetMetadata(source, 'stress', value)
    elseif kind == 'qbcore' then
        player.Functions.SetMetaData('stress', value)
    else
        SetResourceKvp('masked1337:hud:stress:' .. identity, tostring(value))
    end
end

function bridge.loadStress(player, kind, identity)
    if kind == 'esx' then
        local saved = GetResourceKvpString('masked1337:hud:stress:' .. identity)
        if saved then return masked1337.Percent(saved) or 0 end
    end
    return bridge.needs(player, kind).stress or 0
end
