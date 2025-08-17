-- Horses Client Functions for Sheriff Archives
local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------------
-- Open Horses Menu
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openHorses', function()
    local input = lib.inputDialog('Search Horses', {
        {type = 'input', label = 'Horse ID, Name, or Owner', description = 'Enter details to search', required = true}
    })
    
    if input then
        local query = input[1]
        RSGCore.Functions.TriggerCallback('rsg-lawman:server:searchHorses', function(results)
            local options = {}
            
            if results and #results > 0 then
                for i = 1, math.min(10, #results) do
                    local horse = results[i]
                    table.insert(options, {
                        title = (horse.name or 'Unknown Horse') .. ' - ' .. (horse.horseid or 'Unknown'),
                        description = 'Owner: ' .. (horse.citizenid or 'Unknown') .. ' | Breed: ' .. (horse.horse or 'Unknown'),
                        icon = 'fa-solid fa-horse',
                        event = 'rsg-lawman:client:viewHorse',
                        args = {horseid = horse.horseid},
                        arrow = true
                    })
                end
            else
                table.insert(options, {
                    title = 'No results found',
                    description = 'No horses match your search',
                    icon = 'fa-solid fa-magnifying-glass',
                    disabled = true
                })
            end
            
            -- Back button
            table.insert(options, {
                title = 'Back',
                description = 'Return to main Sheriff Archives',
                icon = 'fa-solid fa-arrow-left',
                event = 'rsg-lawman:client:openMDT',
                arrow = true
            })
            
            lib.registerContext({
                id = 'mdt_horses_results',
                title = 'Horse Search Results',
                menu = 'mdt_dashboard',
                options = options
            })
            
            lib.showContext('mdt_horses_results')
        end, query)
    else
        lib.showContext('mdt_dashboard')
    end
end)

------------------------------------------
-- View Horse Details
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewHorse', function(data)
    local horseid = data.horseid
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getHorseDetails', function(horseData)
        local options = {}
        
        -- Horse Information
        table.insert(options, {
            title = 'Horse Information',
            description = 'View horse details',
            icon = 'fa-solid fa-horse',
            event = 'rsg-lawman:client:viewHorseInfo',
            args = {horseData = horseData},
            arrow = true
        })
        
        -- Bounty Alerts
        table.insert(options, {
            title = 'Bounty Alerts',
            description = 'View active bounty alerts for this horse',
            icon = 'fa-solid fa-user-secret',
            event = 'rsg-lawman:client:viewHorseBountyAlerts',
            args = {horseid = horseid},
            arrow = true
        })
        
        -- Create Bounty Alert option
        table.insert(options, {
            title = 'Create Bounty Alert',
            description = 'Create a new bounty alert for this horse',
            icon = 'fa-solid fa-plus',
            event = 'rsg-lawman:client:createHorseBountyAlert',
            args = {horseid = horseid},
            arrow = true
        })
        
        -- Back button
        table.insert(options, {
            title = 'Back',
            description = 'Return to horses search',
            icon = 'fa-solid fa-arrow-left',
            event = 'rsg-lawman:client:openHorses',
            arrow = true
        })
        
        lib.registerContext({
            id = 'mdt_horse_details',
            title = 'Horse Details',
            menu = 'mdt_horses_results',
            options = options
        })
        
        lib.showContext('mdt_horse_details')
    end, horseid)
end)

------------------------------------------
-- View Horse Information
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewHorseInfo', function(data)
    local horseData = data.horseData
    local horse = horseData.horseData
    local options = {}
    
    table.insert(options, {
        title = 'Horse ID',
        description = horse.horseid or 'Unknown',
        icon = 'fa-solid fa-hashtag',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Name',
        description = horse.name or 'Unknown',
        icon = 'fa-solid fa-signature',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Owner',
        description = horse.citizenid or 'Unknown',
        icon = 'fa-solid fa-user',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Breed',
        description = horse.horse or 'Unknown',
        icon = 'fa-solid fa-horse-head',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Gender',
        description = horse.gender or 'Unknown',
        icon = 'fa-solid fa-venus-mars',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Experience',
        description = horse.horsexp or '0',
        icon = 'fa-solid fa-chart-line',
        disabled = true
    })
    
    -- Back button
    table.insert(options, {
        title = 'Back',
        description = 'Return to horse details',
        icon = 'fa-solid fa-arrow-left',
        event = 'rsg-lawman:client:viewHorse',
        args = {horseid = horse.horseid},
        arrow = true
    })
    
    lib.registerContext({
        id = 'mdt_horse_info',
        title = 'Horse Information',
        menu = 'mdt_horse_details',
        options = options
    })
    
    lib.showContext('mdt_horse_info')
end)

------------------------------------------
-- View Horse Bounty Alerts
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewHorseBountyAlerts', function(data)
    local horseid = data.horseid
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getHorseBountyAlerts', function(alerts)
        local options = {}
        
        if alerts and #alerts > 0 then
            for i = 1, #alerts do
                local alert = alerts[i]
                local statusIcon = 'fa-solid fa-question'
                if alert.status == 'active' then
                    statusIcon = 'fa-solid fa-clock'
                elseif alert.status == 'claimed' then
                    statusIcon = 'fa-solid fa-check'
                elseif alert.status == 'expired' then
                    statusIcon = 'fa-solid fa-exclamation'
                end
                
                local rewardText = ""
                if alert.reward and alert.reward > 0 then
                    rewardText = " | Reward: $" .. alert.reward
                end
                
                table.insert(options, {
                    title = alert.reason or 'Unknown reason',
                    description = 'Status: ' .. (alert.status or 'Unknown') .. rewardText .. ' | Date: ' .. (alert.created_at or 'Unknown'),
                    icon = statusIcon,
                    disabled = true
                })
            end
        else
            table.insert(options, {
                title = 'No Bounty Alerts',
                description = 'This horse has no bounty alerts',
                icon = 'fa-solid fa-circle-info',
                disabled = true
            })
        end
        
        -- Create new bounty alert
        table.insert(options, {
            title = 'Create Bounty Alert',
            description = 'Create a new bounty alert for this horse',
            icon = 'fa-solid fa-plus',
            event = 'rsg-lawman:client:createHorseBountyAlert',
            args = {horseid = horseid},
            arrow = true
        })
        
        -- Back button
        table.insert(options, {
            title = 'Back',
            description = 'Return to horse details',
            icon = 'fa-solid fa-arrow-left',
            event = 'rsg-lawman:client:viewHorse',
            args = {horseid = horseid},
            arrow = true
        })
        
        lib.registerContext({
            id = 'mdt_horse_bounty_alerts',
            title = 'Horse Bounty Alerts',
            menu = 'mdt_horse_details',
            options = options
        })
        
        lib.showContext('mdt_horse_bounty_alerts')
    end, horseid)
end)

------------------------------------------
-- Create Horse Bounty Alert
------------------------------------------
RegisterNetEvent('rsg-lawman:client:createHorseBountyAlert', function(data)
    local horseid = data.horseid
    
    local input = lib.inputDialog('Create Horse Bounty Alert', {
        {type = 'textarea', label = 'Reason', description = 'Reason for the bounty alert', required = true},
        {type = 'number', label = 'Reward', description = 'Reward amount ($)', required = false, min = 0},
        {type = 'number', label = 'Expires in Days', description = 'Days until expiration (optional)', required = false, min = 1, max = 365}
    })
    
    if input then
        local reason = input[1]
        local reward = input[2] or 0
        local expires = input[3]
        
        if reason and reason ~= '' then
            local alertData = {
                target_citizenid = horseid,  -- Folosim horseid pentru cai
                reason = reason,
                reward = tonumber(reward) or 0,
                expires_in_days = expires and tonumber(expires) or nil
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:createBountyAlert', function(success)
                if success then
                    lib.notify({
                        title = 'Bounty Alert Created',
                        description = 'Horse bounty alert created successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to create horse bounty alert',
                        type = 'error'
                    })
                end
                -- Return to horse view
                TriggerEvent('rsg-lawman:client:viewHorse', {horseid = horseid})
            end, alertData)
        else
            lib.notify({
                title = 'Error',
                description = 'Reason is required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:viewHorse', {horseid = horseid})
        end
    else
        TriggerEvent('rsg-lawman:client:viewHorse', {horseid = horseid})
    end
end)