local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------------
-- law test alert
------------------------------------------
RSGCore.Commands.Add('testalert', locale('sv_test'), {}, false, function(source)
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local text = locale('sv_test_a')
    TriggerClientEvent('rsg-lawman:client:lawmanAlert', src, playerCoords, text)
end, 'admin')

------------------------------------------
-- search players inventory
------------------------------------------
RSGCore.Commands.Add('searchplayer', locale('sv_searchplayer'), {}, false, function(source)
    local src = source
    TriggerClientEvent('rsg-lawman:client:searchplayer', src)
end)

RegisterNetEvent('rsg-lawman:server:SearchPlayer', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local PlayerData = Player.PlayerData
    local player, distance = RSGCore.Functions.GetClosestPlayer(src)
    if player ~= -1 and distance < Config.SearchDistance then
        local SearchedPlayer = RSGCore.Functions.GetPlayer(tonumber(player))
        if not SearchedPlayer then return end
        exports['rsg-inventory']:OpenInventoryById(src, tonumber(player))
        TriggerClientEvent('RSGCore:Client:Notify', player,
            { title = locale('sv_info'), description = locale('sv_info_a'), type = 'info', duration = 7000 })
    else
        TriggerClientEvent('RSGCore:Client:Notify', src,
            { title = locale('sv_error'), description = locale('sv_error_a'), type = 'error', duration = 7000 })
    end
end)

------------------------------------------
-- law badge
------------------------------------------
RSGCore.Commands.Add('lawbadge', locale('sv_lawbadge'), {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local jobname = Player.PlayerData.job.name
    local onduty = Player.PlayerData.job.onduty
    if onduty and Config.LawJobs[jobname] then
        TriggerClientEvent('rsg-lawman:client:lawbadge', src)
    else
        TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('sv_need_duty'), type = 'error', duration = 5000 })
    end
end)

------------------------------------------
-- law on-duty callback
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getlaw', function(source, cb)
    local lawcount = 0
    local players = RSGCore.Functions.GetRSGPlayers()
    for k, v in pairs(players) do
        if v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            lawcount = lawcount + 1
        end
    end
    cb(lawcount)
end)

-- Add 'unjail' command
RSGCore.Commands.Add('unjail', locale('sv_unjail'), { { name = 'id', help = locale('sv_unjail_id') } }, true,
    function(source, args)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)

        if Player.PlayerData.job.type == 'leo' then -- Check if the player issuing the command is a law enforcement officer
            local playerId = tonumber(args[1])
            if playerId then
                local TargetPlayer = RSGCore.Functions.GetPlayer(playerId)
                if TargetPlayer then
                    -- Trigger the unjail event for the target player
                    TargetPlayer.Functions.SetMetaData('injail', 0) -- server-side release so rsg-prison accepts it
                    TriggerClientEvent('rsg-prison:client:freedom', TargetPlayer.PlayerData.source)
                    -- Notify the player issuing the command
                    TriggerClientEvent('RSGCore:Client:Notify', src,
                        { title = locale('sv_unjail_b'), description = locale('sv_unjail_c'), type = 'success', duration = 5000 })
                    -- Optionally notify the target player
                    TriggerClientEvent('RSGCore:Client:Notify', TargetPlayer.PlayerData.source,
                        { title = locale('sv_unjail_d'), description = locale('sv_unjail_e'), type = 'success', duration = 5000 })
                else
                    TriggerClientEvent('RSGCore:Client:Notify', src,
                        { title = locale('sv_unjail_f'), description = locale('sv_unjail_g'), type = 'error', duration = 5000 })
                end
            else
                TriggerClientEvent('RSGCore:Client:Notify', src,
                    { title = locale('sv_unjail_f'), description = locale('sv_unjail_h'), type = 'error', duration = 5000 })
            end
        else
            -- Notify the player issuing the command if they're not a law enforcement officer
            TriggerClientEvent('RSGCore:Client:Notify', src,
                { title = locale('sv_unjail_f'), description = locale('sv_unjail_j'), type = 'error', duration = 5000 })
        end
    end)

---------------------------
-- lawman alert
---------------------------
local alertLast = {}               -- [src] = GetGameTimer() of the last accepted alert
local ALERT_MIN_GAP = 4000         -- ms; slightly below the 5s client cooldown so legit alerts always pass
local ALERT_MAX_TEXT = 150         -- characters
local ALERT_MAX_DIST = 250.0       -- alert position may not be further than this from the sender

RegisterNetEvent('rsg-lawman:server:lawmanAlert', function(text, coords)
    local src = source

    -- the client supplies the text and position, so never trust them as sent
    if type(text) ~= 'string' or text == '' then return end
    text = text:sub(1, ALERT_MAX_TEXT)

    local now = GetGameTimer()
    if alertLast[src] and now - alertLast[src] < ALERT_MIN_GAP then return end
    alertLast[src] = now

    local pedcoords = GetEntityCoords(GetPlayerPed(src))
    local alertCoords = pedcoords
    if type(coords) == 'vector3' then
        alertCoords = coords
    elseif type(coords) == 'table' and type(coords.x) == 'number' and type(coords.y) == 'number' and type(coords.z) == 'number' then
        alertCoords = vector3(coords.x, coords.y, coords.z)
    end
    if #(alertCoords - pedcoords) > ALERT_MAX_DIST then alertCoords = pedcoords end

    for _, v in pairs(RSGCore.Functions.GetRSGPlayers()) do
        if v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            TriggerClientEvent('rsg-lawman:client:lawmanAlert', v.PlayerData.source, alertCoords, text)
        end
    end
end)

AddEventHandler('playerDropped', function()
    alertLast[source] = nil
end)

-----------------------------------
-- jail player command (law only)
-----------------------------------
RSGCore.Commands.Add('jail', locale('sv_jail'),
    { { name = 'id', help = locale('sv_jail_a') }, { name = 'time', help = locale('sv_jail_b') } }, true,
    function(source, args)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' then
            local playerId = tonumber(args[1])
            local time = tonumber(args[2])
            if time > 0 then
                jailPlayerByPlayer(playerId, src, time)
            else
                TriggerClientEvent('RSGCore:Client:Notify', src,
                    { title = locale('sv_jail_c'), description = locale('sv_jail_d'), type = 'inform', duration = 5000 })
            end
        end
    end)

--------------------------------------------------------------------------------------------------
-- jail player
--------------------------------------------------------------------------------------------------
function jailPlayerByPlayer(targetPlayer, byPlayer, minutes)
    local Player = RSGCore.Functions.GetPlayer(byPlayer)
    local OtherPlayer = RSGCore.Functions.GetPlayer(targetPlayer)
    local time = minutes

    local currentDate = os.date('*t')
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    if Player.PlayerData.job.type == 'leo' then
        if OtherPlayer then
            OtherPlayer.Functions.SetMetaData('injail', time)
            OtherPlayer.Functions.SetMetaData('criminalrecord', { ['hasRecord'] = true, ['date'] = currentDate })
            TriggerClientEvent('rsg-lawman:client:sendtojail', OtherPlayer.PlayerData.source, time)
            TriggerClientEvent('RSGCore:Client:Notify', byPlayer,
                { title = locale('sv_injail') .. ' ' .. time, type = 'success', duration = 5000 })
        end
    end
end

RegisterNetEvent('rsg-lawman:server:jailplayer', function(playerId, minutes)
    jailPlayerByPlayer(playerId, source, minutes)
end)

------------------------------------------
-- handcuff player command
------------------------------------------
RSGCore.Commands.Add('cuff', locale('sv_cuff'), {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' then
        TriggerClientEvent('rsg-lawman:client:cuffplayer', src)
    end
end)

------------------------------------------
-- handcuff player use
------------------------------------------
RSGCore.Functions.CreateUseableItem('handcuffs', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player.Functions.GetItemByName(item.name) then
        TriggerClientEvent('rsg-lawman:client:cuffplayer', src)
    end
end)

------------------------------------------
-- handcuff player
------------------------------------------
RegisterNetEvent('rsg-lawman:server:cuffplayer', function(playerId, isSoftcuff)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' then
        local CuffedPlayer = RSGCore.Functions.GetPlayer(playerId)
        if CuffedPlayer then
            if Player.Functions.GetItemByName('handcuffs') then
                TriggerClientEvent('rsg-lawman:client:getcuffed', CuffedPlayer.PlayerData.source,
                    Player.PlayerData.source, isSoftcuff)
            end
        end
    end
end)

------------------------------------------
-- set handcuff status
------------------------------------------
RegisterNetEvent('rsg-lawman:server:sethandcuffstatus', function(isHandcuffed)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.SetMetaData('ishandcuffed', isHandcuffed)
    end
end)

------------------------------------------
-- escort player command
------------------------------------------
RSGCore.Commands.Add('escort', locale('sv_escort'), {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' then
        TriggerClientEvent('rsg-lawman:client:escortplayer', src)
    end
end)

------------------------------------------
-- set escort status
------------------------------------------
RegisterNetEvent('rsg-lawman:server:setescortstatus', function(isEscorted)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.SetMetaData('isescorted', isEscorted)
    end
end)

------------------------------------------
-- escort player
------------------------------------------
RegisterNetEvent('rsg-lawman:server:escortplayer', function(playerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.type == 'leo' then
        local EscortPlayer = RSGCore.Functions.GetPlayer(playerId)
        if EscortPlayer then
            if (EscortPlayer.PlayerData.metadata['ishandcuffed'] or EscortPlayer.PlayerData.metadata['isdead']) then
                TriggerClientEvent('rsg-lawman:client:getescorted', EscortPlayer.PlayerData.source,
                    Player.PlayerData.source)
            else
                TriggerClientEvent('RSGCore:Client:Notify', Player.PlayerData.source, { title = locale('sv_handcuffedordead'), type = 'error', duration = 5000 })
            end
        end
    end
end)

---------------------------------
-- open law storage
---------------------------------
RegisterServerEvent('rsg-lawman:server:storage', function(jobname)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = locale('sv_storage'), maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local stashName = 'lawstorage' .. jobname
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------
-- update outlaw status
---------------------------------
RegisterServerEvent('rsg-lawman:server:updateoutlawstatus', function(amount, reason)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid = ?', { citizenid })
    local newoutlawstatus = (result[1].outlawstatus + amount)
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
end)
