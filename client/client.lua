local RSGCore = exports['rsg-core']:GetCoreObject()
local blipEntries = {}
local timer = Config.AlertTimer

-------------------------------------------------------------------------------------------
-- prompts and blips if needed
-------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.LawOfficeLocations) do
        exports['rsg-core']:createPrompt(v.prompt, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], 'Open Menu', {
            type = 'client',
            event = 'rsg-lawman:client:mainmenu',
            args = { v.jobaccess },
        })
        if v.showblip == true then
            local LawMenuBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
            SetBlipSprite(LawMenuBlip,  joaat(Config.LawOfficeBlip.blipSprite), true)
            SetBlipScale(Config.LawOfficeBlip.blipScale, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, LawMenuBlip, Config.LawOfficeBlip.blipName)
        end
    end
end)

------------------------------------------
-- main job menu
------------------------------------------
RegisterNetEvent('rsg-lawman:client:mainmenu', function(jobaccess)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    if playerjob == jobaccess then
        lib.registerContext({
            id = 'lawoffice_mainmenu',
            title = 'Law Office Menu',
            options = {
                {
                    title = 'Boss Menu',
                    description = 'open the boss menu',
                    icon = 'fa-solid fa-user-tie',
                    event = 'rsg-bossmenu:client:mainmenu',
                    arrow = true
                },
                {
                    title = 'Toggle Duty',
                    icon = 'fa-solid fa-shield-heart',
                    description = '',
                    event = 'rsg-lawman:client:ToggleDuty',
                    arrow = true
                },
                {
                    title = 'Armoury',
                    description = 'open the armoury',
                    icon = 'fa-solid fa-person-rifle',
                    event = 'rsg-lawman:client:openarmoury',
                    arrow = true
                },
                {
                    title = 'Trash Can',
                    description = 'for items that are no longer needed',
                    icon = 'fa-solid fa-trash-can',
                    event = 'rsg-lawman:client:opentrash',
                    arrow = true
                },
            }
        })
        lib.showContext("lawoffice_mainmenu")
    else
        lib.notify({ title = 'Not Authorised', type = 'error', duration = 5000 })
    end
end)

------------------------------------------
-- law office armoury
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openarmoury')
AddEventHandler('rsg-lawman:client:openarmoury', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            local ArmouryItems = {}
            ArmouryItems.label = "Law Office Armoury"
            ArmouryItems.items = Config.LawOfficeArmoury
            ArmouryItems.slots = #Config.LawOfficeArmoury
            TriggerServerEvent("inventory:server:OpenInventory", "shop", "LawOffice_"..math.random(1, 99), ArmouryItems)
        end
    end)
end)

------------------------------------------
-- send player to jail
------------------------------------------
RegisterNetEvent('rsg-lawman:client:jailplayer', function(playerId, time)
    TriggerServerEvent('rsg-lawman:server:jailplayer', playerId, tonumber(time))
end)

RegisterNetEvent('rsg-lawman:client:sendtojail', function(time)
    TriggerServerEvent('rsg-lawman:server:sethandcuffstatus', false)
    isHandcuffed = false
    isEscorted = false
    ClearPedTasks(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)
    TriggerEvent('rsg-prison:client:Enter', time)
end)

------------------------------------------
-- lawman alert
------------------------------------------
RegisterNetEvent('rsg-lawman:client:lawmanAlert', function(coords, text)

    local blip = Citizen.InvokeNative(0x554D9D53F696D002, joaat('BLIP_STYLE_CREATOR_DEFAULT'), coords.x, coords.y, coords.z)
    local blip2 = Citizen.InvokeNative(0x554D9D53F696D002, joaat('BLIP_STYLE_COP_PERSISTENT'), coords.x, coords.y, coords.z)

    SetBlipSprite(blip, joaat('blip_ambient_law'))
    SetBlipSprite(blip2, joaat('blip_overlay_ring'))
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat('BLIP_MODIFIER_AREA_PULSE'))
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip2, joaat('BLIP_MODIFIER_AREA_PULSE'))
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, text)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip2, text)

    blipEntries[#blipEntries + 1] = {coords = coords, handle = blip}
    blipEntries[#blipEntries + 1] = {coords = coords, handle = blip2}

    -- Add GPS Route

    if Config.AddGPSRoute then
        StartGpsMultiRoute(`COLOR_GREEN`, true, true)
        AddPointToGpsMultiRoute(coords)
        SetGpsMultiRouteRender(true)
    end

    -- send notifcation
    lib.notify({ title = text, type = 'inform', duration = 7000 })

    CreateThread(function ()
        while timer ~= 0 do
            Wait(180 * 4)

            local ped = PlayerPedId()
            local pcoord = GetEntityCoords(ped)
            local distance = #(coords - pcoord)
            timer = timer - 1

            if Config.Debug then
                print('Distance to Alert Blip: '..tostring(distance)..' metres')
            end

            if timer <= 0 or distance < 5.0 then
                for i = 1, #blipEntries do
                    local blips = blipEntries[i]
                    local bcoords = blips.coords

                    if coords == bcoords then
                        if Config.Debug then
                            print('')
                            print('Blip Coords: '..tostring(bcoords))
                            print('Blip Removed: '..tostring(blipEntries[i].handle))
                            print('')
                        end

                        RemoveBlip(blipEntries[i].handle)
                    end
                end

                timer = Config.AlertTimer

                if Config.AddGPSRoute then
                    ClearGpsMultiRoute(coords)
                end

                return
            end
        end
    end)
end)

------------------------------------------
-- trash can
------------------------------------------
RegisterNetEvent('rsg-lawman:client:opentrash', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", 'lawtrashcan', { maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots })
            TriggerEvent("inventory:client:SetCurrentStash", 'lawtrashcan')
        end
    end)
end)

------------------------------------------
-- handcuff player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:cuffplayer', function()
    if not IsPedRagdoll(PlayerPedId()) then
        local player, distance = RSGCore.Functions.GetClosestPlayer()
        if player ~= -1 and distance < 1.5 then
            local result = RSGCore.Functions.HasItem('handcuffs')
            if result then
                local playerId = GetPlayerServerId(player)
                if not IsPedInAnyVehicle(GetPlayerPed(player)) and not IsPedInAnyVehicle(PlayerPedId()) then
                    TriggerServerEvent('rsg-lawman:server:cuffplayer', playerId, false)
                    -- HandCuffAnimation()
                else
                    lib.notify({ title = 'Failed', description = 'you can\'t cuff someone in a vehicle', type = 'error', duration = 5000 })
                end
            else
                lib.notify({ title = 'Handcuffs Needed', description = 'you don\'t have handcuffs on you', type = 'error', duration = 5000 })
            end
        else
            lib.notify({ title = 'No one nearby!', type = 'error', duration = 5000 })
        end
    else
        Wait(2000)
    end
end)

------------------------------------------
-- do handcuff player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:getcuffed', function(playerId, isSoftcuff)
    local ped = PlayerPedId()
    if not isHandcuffed then
        isHandcuffed = true
        TriggerServerEvent('rsg-lawman:server:sethandcuffstatus', true)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'cuff', 0.6)
        ClearPedTasksImmediately(ped)
        if Citizen.InvokeNative(0x8425C5F057012DAB, ped) ~= joaat("WEAPON_UNARMED") then
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        end
        if not isSoftcuff then
            cuffType = 16
            lib.notify({ title = 'You are cuffed!', type = 'inform', duration = 5000 })
        else
            cuffType = 49
            lib.notify({ title = 'You are cuffed!', description = 'but you can walk', type = 'inform', duration = 5000 })
        end
    else
        isHandcuffed = false
        isEscorted = false
        TriggerEvent('hospital:client:isEscorted', isEscorted)
        DetachEntity(ped, true, false)
        TriggerServerEvent('rsg-lawman:server:sethandcuffstatus', false)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'uncuff', 0.6)
        ClearPedTasksImmediately(ped)
        SetEnableHandcuffs(ped, false)
        DisablePlayerFiring(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        DisplayRadar(true)
        if cuffType == 49 then
            FreezeEntityPosition(ped, false)
        end
        lib.notify({ title = 'You are uncuffed!', type = 'inform', duration = 5000 })
    end
end)

------------------------------------------
-- handcuff player loop
------------------------------------------
CreateThread(function()
    local ped = PlayerPedId()
    while true do
        Wait(1)
        if isEscorted or isHandcuffed then
            DisableControlAction(0, 0x295175BF, true) -- Disable break
            DisableControlAction(0, 0x6E9734E8, true) -- Disable suicide
            DisableControlAction(0, 0xD8F73058, true) -- Disable aiminair
            DisableControlAction(0, 0x4CC0E2FE, true) -- B key
            DisableControlAction(0, 0xDE794E3E, true) -- Cover
            DisableControlAction(0, 0x06052D11, true) -- Cover
            DisableControlAction(0, 0x5966D52A, true) -- Cover
            DisableControlAction(0, 0xCEFD9220, true) -- Cover
            DisableControlAction(0, 0xC75C27B0, true) -- Cover
            DisableControlAction(0, 0x41AC83D1, true) -- Cover
            DisableControlAction(0, 0xADEAF48C, true) -- Cover
            DisableControlAction(0, 0x9D2AEA88, true) -- Cover
            DisableControlAction(0, 0xE474F150, true) -- Cover
            DisableControlAction(0, 0xB2F377E8, true) -- Attack
            DisableControlAction(0, 0xC1989F95, true) -- Attack 2
            DisableControlAction(0, 0x07CE1E61, true) -- Melee Attack 1
            DisableControlAction(0, 0xF84FA74F, true) -- MOUSE2
            DisableControlAction(0, 0xCEE12B50, true) -- MOUSE3
            DisableControlAction(0, 0x8FFC75D6, true) -- Shift
            DisableControlAction(0, 0xD9D0E1C0, true) -- SPACE
            DisableControlAction(0, 0xF3830D8E, true) -- J
            DisableControlAction(0, 0x80F28E95, true) -- L
            DisableControlAction(0, 0xDB096B85, true) -- CTRL
            DisableControlAction(0, 0xE30CD707, true) -- R
        end

        if cuffType == 16 and isHandcuffed then  -- soft cuff
            SetEnableHandcuffs(ped, true)
            DisablePlayerFiring(ped, true)
            SetPedCanPlayGestureAnims(ped, false)
            DisplayRadar(false)
        end

        if cuffType == 49 and isHandcuffed then  -- hard cuff
            SetEnableHandcuffs(ped, true)
            DisablePlayerFiring(ped, true)
            SetPedCanPlayGestureAnims(ped, false)
            DisplayRadar(false)
            FreezeEntityPosition(ped, true)
        end

        if not isHandcuffed and not isEscorted then
            Wait(2000)
        end
    end
end)

------------------------------------------
-- Toggle On-Duty
------------------------------------------
AddEventHandler('rsg-lawman:client:ToggleDuty', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            TriggerServerEvent("RSGCore:ToggleDuty")
            return
        end
    end)
end)

------------------------------------------
-- escort player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:escortplayer', function()
    local player, distance = RSGCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if not isHandcuffed and not isEscorted then
            TriggerServerEvent("rsg-lawman:server:escortplayer", playerId)
        end
    else
        lib.notify({ title = 'No one nearby!', type = 'error', duration = 5000 })
    end
end)

------------------------------------------
-- do escort player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:getescorted', function(playerId)
    local ped = PlayerPedId()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.metadata["isdead"] or isHandcuffed then
            if not isEscorted then
                isEscorted = true
                TriggerServerEvent('rsg-lawman:server:setescortstatus', true)
                draggerId = playerId
                local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
                SetEntityCoords(ped, GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.45, 0.0))
                AttachEntityToEntity(ped, dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            else
                isEscorted = false
                TriggerServerEvent('rsg-lawman:server:setescortstatus', false)
                DetachEntity(ped, true, false)
            end
        end
    end)
end)
