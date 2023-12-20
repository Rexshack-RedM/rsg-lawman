local RSGCore = exports['rsg-core']:GetCoreObject()
local blipEntries = {}
local timer = 0

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

                timer = Config.DeathTimer

                if Config.AddGPSRoute then
                    ClearGpsMultiRoute(coords)
                end

                return
            end
        end
    end)
end)
