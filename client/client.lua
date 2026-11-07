local RSGCore = exports['rsg-core']:GetCoreObject()
local blipEntries = {}
local timer = Config.AlertTimer
local badge = false
local lastHealth = 0
local lastPedHealth = {}
local lastAlertTime = 0
local alertCooldown = 5000

------------------------------------------
-- NUI (menus / input) with push-to-talk support
------------------------------------------
local uiFocus = false
menuActions = {}
local inputPromise = nil

local function applyNuiFocus(enable)
    if enable then
        SetNuiFocus(true, true)
        if Config.AllowPushToTalkWhileOpen then
            SetNuiFocusKeepInput(true)
        end
    else
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
end

local function closeUI()
    uiFocus = false
    applyNuiFocus(false)
end

function openUI(data)
    data.confirm = data.confirm or locale('cl_confirm')
    data.cancel = data.cancel or locale('cl_cancel')
    SendNUIMessage(data)
    uiFocus = true
    applyNuiFocus(true)
end

function inputDialog(title, label)
    if inputPromise then return nil end
    inputPromise = promise.new()
    openUI({ action = 'openInput', title = title, label = label })
    local value = Citizen.Await(inputPromise)
    inputPromise = nil
    return value
end

RegisterNUICallback('menuSelect', function(data, cb)
    closeUI()
    cb('ok')
    local fn = menuActions[data and data.id]
    menuActions = {}
    if fn then fn() end
end)

RegisterNUICallback('inputSubmit', function(data, cb)
    closeUI()
    cb('ok')
    local v = tonumber(data and data.value)
    if v then v = math.floor(v) end
    if v and v <= 0 then v = nil end
    if inputPromise then inputPromise:resolve(v) end
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    menuActions = {}
    cb('ok')
end)

CreateThread(function()
    while true do
        if uiFocus and Config.AllowPushToTalkWhileOpen then
            Wait(0)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            for _, ctrl in ipairs(Config.PushToTalkControls or {}) do
                EnableControlAction(0, ctrl, true)
                EnableControlAction(1, ctrl, true)
                EnableControlAction(2, ctrl, true)
            end
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and uiFocus then
        SendNUIMessage({ action = 'close' })
        closeUI()
        if inputPromise then inputPromise:resolve(nil) end
    end
end)

------------------------------------
-- prompts and blips if needed
------------------------------------
CreateThread(function()
    for _, v in pairs(Config.LawOfficeLocations) do
        exports['rsg-core']:createPrompt(v.prompt, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], locale('cl_open'),
            {
                type = 'client',
                event = 'rsg-lawman:client:mainmenu',
                args = { v.jobaccess, v.prompt },
            })
        if v.showblip == true then
            local LawMenuBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(LawMenuBlip, joaat(v.blipsprite), true)
            SetBlipScale(LawMenuBlip, v.blipscale)
            SetBlipName(LawMenuBlip, v.name)
        end
    end
end)

------------------------------------------
-- main job menu
------------------------------------------
RegisterNetEvent('rsg-lawman:client:mainmenu', function(jobaccess, name)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    if playerjob == jobaccess then
        menuActions = {
            duty = function() TriggerEvent('rsg-lawman:client:ToggleDuty') end,
            armoury = function() TriggerEvent('rsg-lawman:client:openarmoury', name) end,
            storage = function() TriggerEvent('rsg-lawman:client:openstorage') end,
        }
        openUI({
            action = 'openMenu',
            title = locale('cl_menu'),
            subtitle = PlayerData.job.label or '',
            options = {
                { id = 'duty', title = locale('cl_duty'), icon = 'fa-solid fa-shield-heart' },
                { id = 'armoury', title = locale('cl_armo'), description = locale('cl_armo_a'), icon = 'fa-solid fa-person-rifle' },
                { id = 'storage', title = locale('cl_trash'), description = locale('cl_trash_a'), icon = 'fa-solid fa-box-archive' },
            }
        })
    else
        RSGCore.Functions.Notify({ title = locale('cl_no_job'), type = 'error', duration = 5000 })
    end
end)

------------------------------------------
-- law office armoury
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openarmoury')
AddEventHandler('rsg-lawman:client:openarmoury', function(id)
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" and PlayerData.job.grade.level >= Config.ArmouryAccessGrade then
            TriggerServerEvent('rsg-shops:server:openstore', 'armoury', 'armoury', locale('cl_shop'))
        else
            RSGCore.Functions.Notify({ title = locale('cl_no_rank'), type = 'error', duration = 7000 })
        end
    end)
end)

------------------------------------------
-- send player to jail
------------------------------------------
RegisterNetEvent('rsg-lawman:client:jailplayer', function(playerId, time)
    if playerId and time then
        -- Jail specific player
        TriggerServerEvent('rsg-lawman:server:jailplayer', playerId, tonumber(time))
    else
        -- Jail closest player
        if not IsPedRagdoll(PlayerPedId()) then
            local distanceRequirement = 1.5

            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player == -1 or distance >= distanceRequirement then
                RSGCore.Functions.Notify({ title = locale('cl_nearby'), type = 'error', duration = 5000 })
                return
            end

            local playerId = GetPlayerServerId(player)
            local time = inputDialog(locale('jail_player_header', playerId), locale('jail_player_time_label'))
            if not time then
                return
            end
            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player == -1 or distance >= distanceRequirement or GetPlayerServerId(player) ~= playerId then
                RSGCore.Functions.Notify({ title = locale('cl_nearby'), type = 'error', duration = 5000 })
                return
            end

            TriggerServerEvent('rsg-lawman:server:jailplayer', playerId, time)
        end
    end
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
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            local blip = BlipAddForCoords(joaat('BLIP_STYLE_CREATOR_DEFAULT'), coords.x, coords.y, coords.z)
            local blip2 = BlipAddForCoords(joaat('BLIP_STYLE_COP_PERSISTENT'), coords.x, coords.y, coords.z)
            local blipText = locale('cl_alert') .. ' - ' .. tostring(text)
            SetBlipSprite(blip, joaat('blip_ambient_law'))
            SetBlipSprite(blip2, joaat('blip_overlay_ring'))
            BlipAddModifier(blip, joaat('BLIP_MODIFIER_AREA_PULSE'))
            BlipAddModifier(blip2, joaat('BLIP_MODIFIER_AREA_PULSE'))
            SetBlipScale(blip, 0.8)
            SetBlipScale(blip2, 2.0)
            SetBlipName(blip, text)
            SetBlipName(blip2, text)

            blipEntries[#blipEntries + 1] = { coords = coords, handle = blip }
            blipEntries[#blipEntries + 1] = { coords = coords, handle = blip2 }

            -- Add GPS Route

            if Config.AddGPSRoute then
                StartGpsMultiRoute(`COLOR_GREEN`, true, true)
                AddPointToGpsMultiRoute(coords)
                SetGpsMultiRouteRender(true)
            end

            -- send notifcation
            RSGCore.Functions.Notify({ title = text, type = 'inform', duration = 7000 })

            CreateThread(function()
                while timer ~= 0 do
                    Wait(180 * 4)

                    local pcoord = GetEntityCoords(PlayerPedId())
                    local distance = #(coords - pcoord)
                    timer = timer - 1

                    if Config.Debug then
                        print('Distance to Alert Blip: ' .. tostring(distance) .. ' metres')
                    end

                    if timer <= 0 or distance < 5.0 then
                        for i = 1, #blipEntries do
                            local blips = blipEntries[i]
                            local bcoords = blips.coords

                            if coords == bcoords then
                                if Config.Debug then
                                    print('')
                                    print('Blip Coords: ' .. tostring(bcoords))
                                    print('Blip Removed: ' .. tostring(blipEntries[i].handle))
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
                    RSGCore.Functions.Notify({ title = locale('cl_failed'), description = locale('cl_failed_a'), type = 'error', duration = 5000 })
                end
            else
                RSGCore.Functions.Notify({ title = locale('cl_handcuffs'), description = locale('cl_handcuffs_a'), type = 'error', duration = 5000 })
            end
        else
            RSGCore.Functions.Notify({ title = locale('cl_nearby'), type = 'error', duration = 5000 })
        end
    else
        Wait(2000)
    end
end)

------------------------------------------
-- do handcuff player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:getcuffed', function(playerId, isSoftcuff)
    if not isHandcuffed then
        isHandcuffed = true
        TriggerServerEvent('rsg-lawman:server:sethandcuffstatus', true)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'cuff', 0.6)
        ClearPedTasksImmediately(PlayerPedId())
        if GetPedCurrentHeldWeapon(PlayerPedId()) ~= joaat("WEAPON_UNARMED") then
            SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
        end
        if not isSoftcuff then
            cuffType = 16
            RSGCore.Functions.Notify({ title = locale('cl_cuffed'), type = 'inform', duration = 5000 })
        else
            cuffType = 49
            RSGCore.Functions.Notify({ title = locale('cl_cuffed'), description = locale('cl_cuffed_a'), type = 'inform', duration = 5000 })
        end
    else
        isHandcuffed = false
        isEscorted = false
        TriggerEvent('hospital:client:isEscorted', isEscorted)
        DetachEntity(PlayerPedId(), true, false)
        TriggerServerEvent('rsg-lawman:server:sethandcuffstatus', false)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'uncuff', 0.6)
        ClearPedTasksImmediately(PlayerPedId())
        SetEnableHandcuffs(PlayerPedId(), false)
        DisablePlayerFiring(PlayerPedId(), false)
        SetPedCanPlayGestureAnims(PlayerPedId(), true)
        DisplayRadar(true)
        if cuffType == 49 then
            FreezeEntityPosition(PlayerPedId(), false)
        end
        RSGCore.Functions.Notify({ title = locale('cl_uncuffed'), type = 'inform', duration = 5000 })
    end
end)

------------------------------------------
-- handcuff player loop
------------------------------------------
CreateThread(function()
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

        if cuffType == 16 and isHandcuffed then -- soft cuff
            SetEnableHandcuffs(PlayerPedId(), true)
            DisablePlayerFiring(PlayerPedId(), true)
            SetPedCanPlayGestureAnims(PlayerPedId(), false)
            DisplayRadar(false)
        end

        if cuffType == 49 and isHandcuffed then -- hard cuff
            SetEnableHandcuffs(PlayerPedId(), true)
            DisablePlayerFiring(PlayerPedId(), true)
            SetPedCanPlayGestureAnims(PlayerPedId(), false)
            DisplayRadar(false)
            FreezeEntityPosition(PlayerPedId(), true)
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
        RSGCore.Functions.Notify({ title = locale('cl_nearby'), type = 'error', duration = 5000 })
    end
end)

------------------------------------------
-- do escort player
------------------------------------------
RegisterNetEvent('rsg-lawman:client:getescorted', function(playerId)
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.metadata["isdead"] or isHandcuffed then
            if not isEscorted then
                isEscorted = true
                TriggerServerEvent('rsg-lawman:server:setescortstatus', true)
                draggerId = playerId
                local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
                SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.45, 0.0))
                AttachEntityToEntity(PlayerPedId(), dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false,
                    false, 2, true)
            else
                isEscorted = false
                TriggerServerEvent('rsg-lawman:server:setescortstatus', false)
                DetachEntity(PlayerPedId(), true, false)
            end
        end
    end)
end)

------------------------------------------
-- law badge
------------------------------------------
RegisterNetEvent('rsg-lawman:client:lawbadge', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        local jobname = PlayerData.job.name
        if Config.LawJobs[jobname] then
            if badge == false then
                if not IsPedMale(PlayerPedId()) then                                                       -- female
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, PlayerPedId(), 0x0929677D, true, true, true)  -- ApplyShopItemToPed
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, false)             -- UpdatePedVariation
                else                                                                                   -- male
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, PlayerPedId(), 0xDB4C451D, true, false, true) -- ApplyShopItemToPed
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, false)             -- UpdatePedVariation
                end
                RSGCore.Functions.Notify({ title = locale('cl_badge_on'), type = 'inform', position = 'center-right', duration = 5000 })
                badge = true
            else
                if not IsPedMale(PlayerPedId()) then                                           -- female
                    Citizen.InvokeNative(0x0D7FFA1B2F69ED82, PlayerPedId(), 0x0929677D, 0, 0)  -- RemoveShopItemFromPed
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, false) -- UpdatePedVariation
                else                                                                       -- male
                    Citizen.InvokeNative(0x0D7FFA1B2F69ED82, PlayerPedId(), 0xDB4C451D, 0, 0)  -- RemoveShopItemFromPed
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, PlayerPedId(), 0, 1, 1, 1, false) -- UpdatePedVariation
                end
                RSGCore.Functions.Notify({ title = locale('cl_badge_off'), type = 'inform', position = 'center-right', duration = 5000 })
                badge = false
            end
        else
            RSGCore.Functions.Notify({ title = locale('cl_only_law'), type = 'inform', position = 'center-right', duration = 5000 })
        end
    end)
end)

------------------------------------------
-- search other players inventory
------------------------------------------
RegisterNetEvent('rsg-lawman:client:searchplayer', function()
    if not IsPedRagdoll(PlayerPedId()) then
        local player, distance = RSGCore.Functions.GetClosestPlayer()
        if player ~= -1 and distance < Config.SearchDistance then
            local playerPed = GetPlayerPed(player)
            local playerId = GetPlayerServerId(player)
            local isdead = IsEntityDead(playerPed)
            local cuffed = IsPedCuffed(playerPed)
            local hogtied = Citizen.InvokeNative(0x3AA24CCC0D451379, playerPed)
            local lassoed = Citizen.InvokeNative(0x9682F850056C9ADE, playerPed)
            local ragdoll = IsPedRagdoll(playerPed)
            if isdead or cuffed or hogtied or lassoed or ragdoll or IsEntityPlayingAnim(playerPed, "script_proc@robberies@homestead@lonnies_shack@deception", "hands_up_loop", 3) then
                TriggerServerEvent('rsg-lawman:server:SearchPlayer')
            else
                RSGCore.Functions.Notify({ title = locale('cl_search'), type = 'inform', position = 'center-right', duration = 5000 })
            end
        else
            RSGCore.Functions.Notify({ title = locale('cl_nearby'), type = 'inform', position = 'center-right', duration = 5000 })
        end
    else
        RSGCore.Functions.Notify({ title = locale('cl_no_be_able'), type = 'inform', position = 'center-right', duration = 5000 })
    end
end)

------------------------------------------
-- open law trashcan
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openstorage', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == 'leo' then
            local jobname = PlayerData.job.name
            TriggerServerEvent('rsg-lawman:server:storage', jobname)
        end
    end)
end)

CreateThread(function()
    if PlayerPedId() then
        lastHealth = GetEntityHealth(PlayerPedId())
    end
end)

-- Helper function to get location name
local function GetLocationName(coords)
    local town = GetClosestTown(coords)
    return town or "Unknown Location"
end

-- Get closest town name
function GetClosestTown(coords)
    -- Define major locations in the game
    local locations = {
        ["Saint Denis"] = vector3(2683.0, -1455.0, 46.0),
        ["Valentine"] = vector3(-283.0, 805.0, 119.0),
        ["Blackwater"] = vector3(-875.0, -1328.0, 43.0),
        ["Rhodes"] = vector3(1359.0, -1299.0, 77.0),
        ["Annesburg"] = vector3(2913.0, 1311.0, 44.0),
        ["Strawberry"] = vector3(-1826.0, -420.0, 160.0),
        ["Tumbleweed"] = vector3(-5517.0, -2940.0, -2.0),
        ["Armadillo"] = vector3(-3743.0, -2595.0, -13.0),
        ["Van Horn"] = vector3(2985.0, 571.0, 44.0),
    }

    local closestDist = math.huge
    local closestLocation = "Wilderness"

    for name, loc in pairs(locations) do
        local dist = #(coords - loc)
        if dist < closestDist then
            closestDist = dist
            closestLocation = name
        end
    end

    return closestLocation
end

local function IsEntityAnimal(entity)
    if not DoesEntityExist(entity) then return false end

    local pedType = GetPedType(entity) -- Get the ped type

    return pedType == 28               -- Animals have ped type 28 in RedM
end

-- Monitor player deaths
CreateThread(function()
    -- Only run this thread if player death alerts are enabled
    if not Config.EnablePlayerDeathAlerts then return end

    while true do
        Wait(1000) -- Check every second

        if PlayerPedId() and DoesEntityExist(PlayerPedId()) then
            local currentHealth = GetEntityHealth(PlayerPedId())

            -- Detect if player just died
            if currentHealth <= 0 and lastHealth > 0 then
                local coords = GetEntityCoords(PlayerPedId())
                local location = GetLocationName(coords)
                local killer = GetPedSourceOfDeath(PlayerPedId())

                -- Ensure killer is valid and not an animal
                local alertText = locale('cl_lang_1') .. location

                if killer and DoesEntityExist(killer) then
                    local killerType = GetEntityType(killer)

                    if killerType == 1 and IsPedAPlayer(killer) then
                        alertText = locale('cl_lang_2') .. location
                    elseif killerType == 1 and not IsEntityAnimal(killer) then
                        alertText = locale('cl_lang_3') .. location
                    end
                end

                -- Cooldown system to prevent spam
                if GetGameTimer() - lastAlertTime > alertCooldown then
                    TriggerServerEvent('rsg-lawman:server:lawmanAlert', alertText, coords)
                    lastAlertTime = GetGameTimer()
                end
            end

            lastHealth = currentHealth
        end
    end
end)

CreateThread(function()
    -- Only run this thread if NPC death alerts are enabled
    if not Config.EnableNPCDeathAlerts then return end

    while true do
        Wait(1000)

        if PlayerPedId() and DoesEntityExist(PlayerPedId()) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local peds = GetGamePool('CPed')

            for _, ped in ipairs(peds) do
                if ped ~= PlayerPedId() and not IsPedAPlayer(ped) and not IsEntityAnimal(ped) then
                    local currentHealth = GetEntityHealth(ped)
                    local lastPedHealthValue = lastPedHealth[ped] or currentHealth

                    -- Detect if NPC just died
                    if currentHealth <= 0 and lastPedHealthValue > 0 then
                        local pedCoords = GetEntityCoords(ped)
                        local distance = #(playerCoords - pedCoords)

                        -- Only alert for deaths within configured distance
                        if distance <= Config.AlertDistance then
                            local location = GetLocationName(pedCoords)
                            local killer = GetPedSourceOfDeath(ped)

                            local alertText = locale('cl_lang_4') .. location

                            -- Add context if killed by player
                            if killer == PlayerPedId() then
                                alertText = locale('cl_lang_5') .. location
                            end

                            -- Cooldown system to prevent spam
                            if GetGameTimer() - lastAlertTime > alertCooldown then
                                TriggerServerEvent('rsg-lawman:server:lawmanAlert', alertText, pedCoords)
                                lastAlertTime = GetGameTimer()
                            end
                        end
                    end

                    lastPedHealth[ped] = currentHealth
                end
            end

            -- Cleanup old ped entries
            for ped in pairs(lastPedHealth) do
                if not DoesEntityExist(ped) then
                    lastPedHealth[ped] = nil
                end
            end
        end
    end
end)
