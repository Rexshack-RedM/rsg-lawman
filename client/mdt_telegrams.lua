------------------------------------------
-- Telegrams Client Functions
------------------------------------------
local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------------
-- Open Telegrams Menu
------------------------------------------
RegisterNetEvent('rsg-lawman:client:openTelegrams', function()
    -- Request telegram data from server
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getTelegrams', function(telegrams)
        local options = {}
        
        -- Header
        table.insert(options, {
            title = 'Received Telegrams',
            description = 'View and manage your telegrams',
            icon = 'fa-solid fa-envelope',
            disabled = true
        })
        
        if telegrams and #telegrams > 0 then
            for i = 1, math.min(15, #telegrams) do
                local telegram = telegrams[i]
                local statusIcon = 'fa-solid fa-envelope'
                local statusText = 'Unread'
                
                if telegram.status == '1' then
                    statusIcon = 'fa-solid fa-envelope-open'
                    statusText = 'Read'
                end
                
                table.insert(options, {
                    title = telegram.subject or 'No Subject',
                    description = 'From: ' .. (telegram.sendername or telegram.sender or 'Unknown') .. ' | Status: ' .. statusText,
                    icon = statusIcon,
                    event = 'rsg-lawman:client:viewTelegram',
                    args = {telegramId = telegram.id, telegram = telegram},
                    arrow = true
                })
            end
        else
            table.insert(options, {
                title = 'No Telegrams',
                description = 'You have no telegrams',
                icon = 'fa-solid fa-envelope-circle-xmark',
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
            id = 'mdt_telegrams',
            title = 'Telegram Inbox',
            menu = 'mdt_dashboard',
            options = options
        })
        
        lib.showContext('mdt_telegrams')
    end)
end)

------------------------------------------
-- View Telegram Details
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewTelegram', function(data)
    local telegramId = data.telegramId
    local telegram = data.telegram
    
    local options = {}
    
    -- Telegram Details
    table.insert(options, {
        title = 'Subject',
        description = telegram.subject or 'No Subject',
        icon = 'fa-solid fa-heading',
        disabled = true
    })
    
    table.insert(options, {
        title = 'From',
        description = telegram.sendername or telegram.sender or 'Unknown Sender',
        icon = 'fa-solid fa-user',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Date',
        description = telegram.sentDate or 'Unknown Date',
        icon = 'fa-solid fa-calendar',
        disabled = true
    })
    
    -- Message content (scrollable)
    table.insert(options, {
        title = 'Message',
        description = string.sub(telegram.message or 'No message content', 1, 100) .. (string.len(telegram.message or '') > 100 and '...' or ''),
        icon = 'fa-solid fa-message',
        disabled = true
    })
    
    -- Mark as Read option (only if unread)
    if telegram.status == '0' then
        table.insert(options, {
            title = 'Mark as Read',
            description = 'Mark this telegram as read',
            icon = 'fa-solid fa-check',
            event = 'rsg-lawman:client:markTelegramAsRead',
            args = {telegramId = telegramId},
            arrow = true
        })
    end
    
    -- Reply option
    table.insert(options, {
        title = 'Reply',
        description = 'Send a reply to this telegram',
        icon = 'fa-solid fa-reply',
        event = 'rsg-lawman:client:replyToTelegram',
        args = {recipient = telegram.sender, subject = 'Re: ' .. (telegram.subject or 'No Subject')},
        arrow = true
    })
    
    -- Back button
    table.insert(options, {
        title = 'Back',
        description = 'Return to telegram inbox',
        icon = 'fa-solid fa-arrow-left',
        event = 'rsg-lawman:client:openTelegrams',
        arrow = true
    })
    
    lib.registerContext({
        id = 'mdt_telegram_details',
        title = 'Telegram Details',
        menu = 'mdt_telegrams',
        options = options
    })
    
    lib.showContext('mdt_telegram_details')
end)

------------------------------------------
-- Mark Telegram as Read
------------------------------------------
RegisterNetEvent('rsg-lawman:client:markTelegramAsRead', function(data)
    local telegramId = data.telegramId
    
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:markTelegramAsRead', function(success)
        if success then
            lib.notify({
                title = 'Telegram Updated',
                description = 'Telegram marked as read',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Error',
                description = 'Failed to mark telegram as read',
                type = 'error'
            })
        end
        -- Refresh telegram list
        TriggerEvent('rsg-lawman:client:openTelegrams')
    end, telegramId)
end)

------------------------------------------
-- Reply to Telegram
------------------------------------------
RegisterNetEvent('rsg-lawman:client:replyToTelegram', function(data)
    local recipient = data.recipient
    local subject = data.subject
    
    local input = lib.inputDialog('Reply to Telegram', {
        {type = 'input', label = 'Subject', description = 'Telegram subject', required = true, default = subject},
        {type = 'textarea', label = 'Message', description = 'Telegram message', required = true}
    })
    
    if input then
        local replySubject = input[1]
        local replyMessage = input[2]
        
        if replySubject and replySubject ~= '' and replyMessage and replyMessage ~= '' then
            local telegram = {
                recipient = recipient,
                subject = replySubject,
                message = replyMessage
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:sendTelegram', function(success)
                if success then
                    lib.notify({
                        title = 'Reply Sent',
                        description = 'Telegram reply sent successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to send telegram reply',
                        type = 'error'
                    })
                end
                -- Return to telegram inbox
                TriggerEvent('rsg-lawman:client:openTelegrams')
            end, telegram)
        else
            lib.notify({
                title = 'Error',
                description = 'Subject and message are required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:openTelegrams')
        end
    else
        TriggerEvent('rsg-lawman:client:openTelegrams')
    end
end)