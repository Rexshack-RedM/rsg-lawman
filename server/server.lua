local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------------
-- law test alert
------------------------------------------
RSGCore.Commands.Add("testalert", "send test alert", {}, false, function(source)
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local text = "testing"
    TriggerClientEvent('rsg-lawman:client:lawmanAlert', src, playerCoords, text)
end)

------------------------------------------
-- search players inventory
------------------------------------------
RSGCore.Commands.Add('searchplayer', 'Search other players inventory', {}, false, function(source)
    local src = source
    TriggerClientEvent('rsg-lawman:client:SearchPlayer', src)
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
        TriggerClientEvent('ox_lib:notify', player, {title = 'Info', description = Lang:t('lang38'), type = 'info', duration = 7000 })
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = Lang:t('lang35'), type = 'error', duration = 7000 })
    end
end)

------------------------------------------
-- law badge
------------------------------------------
RSGCore.Commands.Add('lawbadge', 'put on / take off badge', {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local jobname = Player.PlayerData.job.name
    local onduty = Player.PlayerData.job.onduty
    if onduty and jobname == 'vallaw' or jobname == 'rholaw' or jobname == 'blklaw' or jobname == 'strlaw' or jobname == 'stdenlaw' then
        TriggerClientEvent('rsg-lawman:client:lawbadge', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Need to be on duty', type = 'error', duration = 5000 })
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

--------------------------------------------------------------------------------------------------
-- lawman alert
--------------------------------------------------------------------------------------------------

RegisterNetEvent('rsg-lawman:server:lawmanAlert', function(text, coords)
    local src = source
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, v in pairs(players) do
        if v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            if coords then
                TriggerClientEvent('rsg-lawman:client:lawmanAlert', v.PlayerData.source, coords, text)
            else
                TriggerClientEvent('rsg-lawman:client:lawmanAlert', v.PlayerData.source, pedCoords, text)
            end
        end
    end
end)

--------------------------------------------------------------------------------------------------
-- jail player command (law only)
--------------------------------------------------------------------------------------------------
RSGCore.Commands.Add('jail', Lang:t('lang20'), {{name = 'id', help =  Lang:t('lang21')}, {name = 'time', help = Lang:t('lang22')}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
        if Player.PlayerData.job.type == 'leo' then
            local playerId = tonumber(args[1])
            local time = tonumber(args[2])
            if time > 0 then
                TriggerClientEvent('rsg-lawman:client:jailplayer', src, playerId, time)
            else
                TriggerClientEvent('ox_lib:notify', src, {title = Lang:t('lang23'), description = Lang:t('lang24'), type = 'inform', duration = 5000 })
            end
        end
end)

--------------------------------------------------------------------------------------------------
-- jail player
--------------------------------------------------------------------------------------------------
RegisterNetEvent('rsg-lawman:server:jailplayer', function(playerId, time)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local OtherPlayer = RSGCore.Functions.GetPlayer(playerId)
    local currentDate = os.date("*t")
    if currentDate.day == 31 then
        currentDate.day = 30
    end

        if Player.PlayerData.job.type == 'leo' then
            if OtherPlayer then
                OtherPlayer.Functions.SetMetaData('injail', time)
                OtherPlayer.Functions.SetMetaData('criminalrecord', { ['hasRecord'] = true, ['date'] = currentDate })
                TriggerClientEvent('rsg-lawman:client:sendtojail', OtherPlayer.PlayerData.source, time)
                TriggerClientEvent('ox_lib:notify', src, {title =  Lang:t('lang25')..time, type = 'success', duration = 5000 })
            end
        end
end)

------------------------------------------
-- handcuff player command
------------------------------------------
RSGCore.Commands.Add('cuff',  Lang:t('lang26'), {}, false, function(source, args)
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
                TriggerClientEvent('rsg-lawman:client:getcuffed', CuffedPlayer.PlayerData.source, Player.PlayerData.source, isSoftcuff)
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
RSGCore.Commands.Add('escort', Lang:t('lang27'), {}, false, function(source, args)
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
                TriggerClientEvent('rsg-lawman:client:getescorted', EscortPlayer.PlayerData.source, Player.PlayerData.source)
            else
                lib.notify({ title = Lang:t('lang28'), type = 'error', duration = 5000 })
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
    local data = { label = 'Law Storage', maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local stashName = 'lawstorage'.. jobname
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)
