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
                    title = 'Armoury',
                    description = 'open the armoury',
                    icon = 'fa-solid fa-person-rifle',
                    event = 'rsg-lawman:client:openarmoury',
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
-- law office armory
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openarmoury')
AddEventHandler('rsg-lawman:client:openarmoury', function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    if playerjob == 'vallaw' or playerjob == 'rholaw' or playerjob == 'blklaw' or playerjob == 'strlaw' or playerjob == 'stdenlaw' then
        local ArmouryItems = {}
        ArmouryItems.label = "Law Office Armory"
        ArmouryItems.items = Config.LawOfficeArmoury
        ArmouryItems.slots = #Config.LawOfficeArmoury
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "LawOffice_"..math.random(1, 99), ArmouryItems)
    else
        lib.notify({ title = 'Not Authorised', type = 'error', duration = 5000 })
    end
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
