-- Bounty Alerts Client Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

------------------------------------------
-- Open Bounty Alerts Menu
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openBountyAlerts', function()
    -- Cerem lista cu bounty alerts active de la server
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getActiveBountyAlerts', function(alerts)
        local options = {}
        
        if alerts and #alerts > 0 then
            for i = 1, math.min(20, #alerts) do
                local alert = alerts[i]
                local charinfo = alert.charinfo
                if type(charinfo) == "string" then
                    charinfo = json.decode(charinfo)
                end
                
                local targetName = "Unknown"
                if charinfo and charinfo.firstname then
                    targetName = charinfo.firstname .. " " .. (charinfo.lastname or "")
                end
                
                local rewardText = ""
                if alert.reward and alert.reward > 0 then
                    rewardText = " | Reward: $" .. alert.reward
                end
                
                table.insert(options, {
                    title = targetName .. " (" .. alert.target_citizenid .. ")",
                    description = alert.reason .. rewardText,
                    icon = 'fa-solid fa-user-secret',
                    event = 'rsg-lawman:client:viewBountyAlertDetails',
                    args = {alert = alert},
                    arrow = true
                })
            end
        else
            table.insert(options, {
                title = 'No Active Bounty Alerts',
                description = 'There are currently no active bounty alerts',
                icon = 'fa-solid fa-circle-info',
                disabled = true
            })
        end
        
        -- Buton pentru creare bounty alert nou
        table.insert(options, {
            title = 'Create Bounty Alert',
            description = 'Create a new bounty alert for a citizen',
            icon = 'fa-solid fa-plus',
            event = 'rsg-lawman:client:createBountyAlert',
            arrow = true
        })
        
        -- Buton înapoi
        table.insert(options, {
            title = 'Back',
            description = 'Return to main MDT menu',
            icon = 'fa-solid fa-arrow-left',
            event = 'rsg-lawman:client:openMDT',
            arrow = true
        })
        
        lib.registerContext({
            id = 'mdt_bounty_alerts',
            title = 'Bounty Alerts',
            menu = 'mdt_dashboard',
            options = options
        })
        
        lib.showContext('mdt_bounty_alerts')
    end)
end)

------------------------------------------
-- Create Bounty Alert
------------------------------------------
RegisterNetEvent('rsg-lawman:client:createBountyAlert', function()
    local input = lib.inputDialog('Create Bounty Alert', {
        {type = 'input', label = 'Target Citizen ID', description = 'Citizen ID of the target', required = true},
        {type = 'textarea', label = 'Reason', description = 'Reason for the bounty alert', required = true},
        {type = 'number', label = 'Reward', description = 'Reward amount ($)', required = false, min = 0},
        {type = 'number', label = 'Expires in Days', description = 'Days until expiration (optional)', required = false, min = 1, max = 365}
    })
    
    if input then
        local citizenid = input[1]
        local reason = input[2]
        local reward = input[3] or 0
        local expires = input[4]
        
        if citizenid and reason and reason ~= '' then
            local alertData = {
                target_citizenid = citizenid,
                reason = reason,
                reward = tonumber(reward) or 0,
                expires_in_days = expires and tonumber(expires) or nil
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:createBountyAlert', function(success)
                if success then
                    lib.notify({
                        title = 'Bounty Alert Created',
                        description = 'Bounty alert created successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to create bounty alert',
                        type = 'error'
                    })
                end
                -- Reîncărcăm meniul de bounty alerts
                TriggerEvent('rsg-lawman:client:openBountyAlerts')
            end, alertData)
        else
            lib.notify({
                title = 'Error',
                description = 'Target Citizen ID and Reason are required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:openBountyAlerts')
        end
    else
        TriggerEvent('rsg-lawman:client:openBountyAlerts')
    end
end)

------------------------------------------
-- View Bounty Alert Details
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewBountyAlertDetails', function(data)
    local alert = data.alert
    local charinfo = alert.charinfo
    if type(charinfo) == "string" then
        charinfo = json.decode(charinfo)
    end
    
    local targetName = "Unknown"
    if charinfo and charinfo.firstname then
        targetName = charinfo.firstname .. " " .. (charinfo.lastname or "")
    end
    
    local options = {}
    
    -- Informații despre bounty alert
    table.insert(options, {
        title = 'Target',
        description = targetName .. " (" .. alert.target_citizenid .. ")",
        icon = 'fa-solid fa-user',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Reason',
        description = alert.reason or 'No reason provided',
        icon = 'fa-solid fa-file-contract',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Reward',
        description = '$' .. (alert.reward or '0'),
        icon = 'fa-solid fa-money-bill',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Issued By',
        description = alert.issued_by or 'Unknown',
        icon = 'fa-solid fa-user-shield',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Status',
        description = alert.status or 'Unknown',
        icon = 'fa-solid fa-info-circle',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Created',
        description = alert.created_at or 'Unknown',
        icon = 'fa-solid fa-calendar',
        disabled = true
    })
    
    if alert.expires_at then
        table.insert(options, {
            title = 'Expires',
            description = alert.expires_at,
            icon = 'fa-solid fa-clock',
            disabled = true
        })
    end
    
    -- Buton pentru a revendica bounty alert-ul (doar pentru ofițeri)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData.job.type == "leo" and alert.status == 'active' then
        table.insert(options, {
            title = 'Claim Bounty',
            description = 'Mark this bounty as claimed',
            icon = 'fa-solid fa-check',
            event = 'rsg-lawman:client:claimBountyAlert',
            args = {alertId = alert.id},
            arrow = true
        })
    end
    
    -- Buton pentru a actualiza statusul (doar pentru ofițeri)
    if PlayerData.job.type == "leo" then
        table.insert(options, {
            title = 'Update Status',
            description = 'Change the status of this bounty alert',
            icon = 'fa-solid fa-edit',
            event = 'rsg-lawman:client:updateBountyAlertStatus',
            args = {alertId = alert.id},
            arrow = true
        })
    end
    
    -- Buton înapoi
    table.insert(options, {
        title = 'Back',
        description = 'Return to bounty alerts list',
        icon = 'fa-solid fa-arrow-left',
        event = 'rsg-lawman:client:openBountyAlerts',
        arrow = true
    })
    
    lib.registerContext({
        id = 'mdt_bounty_alert_details',
        title = 'Bounty Alert Details',
        menu = 'mdt_bounty_alerts',
        options = options
    })
    
    lib.showContext('mdt_bounty_alert_details')
end)

------------------------------------------
-- Claim Bounty Alert
------------------------------------------
RegisterNetEvent('rsg-lawman:client:claimBountyAlert', function(data)
    local alertId = data.alertId
    
    local alert = lib.alertDialog({
        header = 'Confirm Claim',
        content = 'Are you sure you want to claim this bounty alert?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        RSGCore.Functions.TriggerCallback('rsg-lawman:server:claimBountyAlert', function(success)
            if success then
                lib.notify({
                    title = 'Bounty Claimed',
                    description = 'Bounty alert claimed successfully',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Error',
                    description = 'Failed to claim bounty alert',
                    type = 'error'
                })
            end
            -- Reîncărcăm meniul de bounty alerts
            TriggerEvent('rsg-lawman:client:openBountyAlerts')
        end, alertId)
    else
        lib.showContext('mdt_bounty_alert_details')
    end
end)

------------------------------------------
-- Update Bounty Alert Status
------------------------------------------
RegisterNetEvent('rsg-lawman:client:updateBountyAlertStatus', function(data)
    local alertId = data.alertId
    
    local input = lib.inputDialog('Update Bounty Alert Status', {
        {type = 'select', label = 'Status', description = 'Select new status', required = true, options = {
            {value = 'active', label = 'Active'},
            {value = 'claimed', label = 'Claimed'},
            {value = 'expired', label = 'Expired'}
        }}
    })
    
    if input then
        local status = input[1]
        
        RSGCore.Functions.TriggerCallback('rsg-lawman:server:updateBountyAlertStatus', function(success)
            if success then
                lib.notify({
                    title = 'Status Updated',
                    description = 'Bounty alert status updated successfully',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Error',
                    description = 'Failed to update bounty alert status',
                    type = 'error'
                })
            end
            -- Reîncărcăm meniul de bounty alerts
            TriggerEvent('rsg-lawman:client:openBountyAlerts')
        end, alertId, status)
    else
        lib.showContext('mdt_bounty_alert_details')
    end
end)

------------------------------------------
-- View Person Bounty Alerts (din interfața de persoane)
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewPersonBountyAlerts', function(data)
    local citizenid = data.citizenid
    
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getPersonBountyAlerts', function(alerts)
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
                description = 'This person has no bounty alerts',
                icon = 'fa-solid fa-circle-info',
                disabled = true
            })
        end
        
        -- Buton pentru creare bounty alert nou pentru această persoană
        table.insert(options, {
            title = 'Create Bounty Alert',
            description = 'Create a new bounty alert for this person',
            icon = 'fa-solid fa-plus',
            event = 'rsg-lawman:client:createBountyAlertForPerson',
            args = {citizenid = citizenid},
            arrow = true
        })
        
        -- Buton înapoi
        table.insert(options, {
            title = 'Back',
            description = 'Return to person details',
            icon = 'fa-solid fa-arrow-left',
            event = 'rsg-lawman:client:viewPerson',
            args = {citizenid = citizenid},
            arrow = true
        })
        
        lib.registerContext({
            id = 'mdt_person_bounty_alerts',
            title = 'Person Bounty Alerts',
            menu = 'mdt_person_details',
            options = options
        })
        
        lib.showContext('mdt_person_bounty_alerts')
    end, citizenid)
end)

------------------------------------------
-- Create Bounty Alert for Person
------------------------------------------
RegisterNetEvent('rsg-lawman:client:createBountyAlertForPerson', function(data)
    local citizenid = data.citizenid
    
    local input = lib.inputDialog('Create Bounty Alert', {
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
                target_citizenid = citizenid,
                reason = reason,
                reward = tonumber(reward) or 0,
                expires_in_days = expires and tonumber(expires) or nil
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:createBountyAlert', function(success)
                if success then
                    lib.notify({
                        title = 'Bounty Alert Created',
                        description = 'Bounty alert created successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to create bounty alert',
                        type = 'error'
                    })
                end
                -- Reîncărcăm detaliile persoanei
                TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
            end, alertData)
        else
            lib.notify({
                title = 'Error',
                description = 'Reason is required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
        end
    else
        TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
    end
end)