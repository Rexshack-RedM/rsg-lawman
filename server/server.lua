local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-lawman/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

RSGCore.Commands.Add("testalert", "send test alert", {}, false, function(source)
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local text = "testing"
    TriggerClientEvent('rsg-lawman:client:lawmanAlert', src, playerCoords, text)
end)

--------------------------------------------------------------------------------------------------
-- jail player command (law only)
--------------------------------------------------------------------------------------------------
RSGCore.Commands.Add("jail", "Jail Player (Law Only)", {{name = "id", help = "ID of Player"}, {name = "time", help = "Time they have to be in jail"}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local playerjob = Player.PlayerData.job.name
    for _, job in pairs(Config.LawJobs) do
        if playerjob == job then
            local playerId = tonumber(args[1])
            local time = tonumber(args[2])
            if time > 0 then
                TriggerClientEvent('rsg-lawman:client:jailplayer', src, playerId, time)
            else
                TriggerClientEvent('ox_lib:notify', src, {title = 'Invalid Jail Time', description = 'jail time needs to be higher than 0', type = 'inform', duration = 5000 })
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------
-- jail player
--------------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-lawman:server:jailplayer', function(playerId, time)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local playerjob = Player.PlayerData.job.name
    local OtherPlayer = RSGCore.Functions.GetPlayer(playerId)
    local currentDate = os.date("*t")
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    for _, job in pairs(Config.LawJobs) do
        if playerjob == job then
            if OtherPlayer then
                OtherPlayer.Functions.SetMetaData('injail', time)
                OtherPlayer.Functions.SetMetaData('criminalrecord', { ['hasRecord'] = true, ['date'] = currentDate })
                TriggerClientEvent('rsg-lawman:client:sendtojail', OtherPlayer.PlayerData.source, time)
                TriggerClientEvent('ox_lib:notify', src, {title = 'Sent to Jail for '..time, type = 'success', duration = 5000 })
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------
-- lawman tash can collection system
--------------------------------------------------------------------------------------------------
UpkeepInterval = function()
    local result = MySQL.query.await('SELECT * FROM stashitems')

    local stash = result[1].stash
    local items = result[1].items

    if stash == 'lawtrashcan' and items == '[]' then 
        if Config.Debug then
            print('trash already taken out')
        end
        goto continue
    end

    MySQL.update('UPDATE stashitems SET items = ? WHERE stash = ?',{ '[]', 'lawtrashcan' })

    if Config.Debug then
        print('law trash removal complete')
    end

    ::continue::

    SetTimeout(Config.TrashCollection * (60 * 1000), UpkeepInterval)
end

SetTimeout(Config.TrashCollection * (60 * 1000), UpkeepInterval)

-----------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()