-- Send Telegram Server Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']

------------------------------------------
-- Send Telegram to Citizen
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:sendTelegram', function(source, cb, telegram)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    print("Sheriff's Archives Server: Send telegram requested by player " .. tostring(src))
    print("Sheriff's Archives Server: Telegram data - Recipient: " .. tostring(telegram.recipient) .. 
          ", Subject: " .. tostring(telegram.subject) .. 
          ", Message: " .. tostring(telegram.message))
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        print("Sheriff's Archives Server: Player " .. tostring(src) .. " is not authorized to send telegram")
        cb(false)
        return
    end
    
    -- Get recipient player data
    local recipientPlayer = MySQL.single.await([[
        SELECT citizenid, charinfo 
        FROM players 
        WHERE citizenid = ?
    ]], { telegram.recipient })
    
    if not recipientPlayer then
        print("Sheriff's Archives Server: Recipient " .. tostring(telegram.recipient) .. " not found")
        cb(false)
        return
    end
    
    -- Parse recipient charinfo to get their name
    local recipientCharinfo = type(recipientPlayer.charinfo) == "string" and json.decode(recipientPlayer.charinfo) or recipientPlayer.charinfo
    local recipientName = (recipientCharinfo.firstname or "Unknown") .. " " .. (recipientCharinfo.lastname or "")
    
    -- Get sender name (law officer)
    local senderCharinfo = type(Player.PlayerData.charinfo) == "string" and json.decode(Player.PlayerData.charinfo) or Player.PlayerData.charinfo
    local senderName = (senderCharinfo.firstname or "Unknown") .. " " .. (senderCharinfo.lastname or "")
    local senderJob = Player.PlayerData.job.label or "Law Officer"
    local senderFull = senderName .. " (" .. senderJob .. ")"
    
    -- Insert telegram using rsg-telegram's table structure
    local insertId = MySQL.insert.await([[
        INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, '0')
    ]], { 
        telegram.recipient,
        recipientName,
        Player.PlayerData.citizenid,
        senderFull,
        telegram.subject,
        os.date("%m/%d/%Y %H:%M"),
        telegram.message
    })
    
    print("Sheriff's Archives Server: Telegram insert result - Insert ID: " .. tostring(insertId))
    
    if insertId then
        print("Sheriff's Archives Server: Telegram sent successfully")
        -- Log the creation
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'telegram_sent', 
            'Sent telegram to: ' .. telegram.recipient,
            Player.PlayerData.citizenid
        })
        
        -- Also update the sender's unread count if they open the telegram app
        exports.oxmysql:execute('SELECT COUNT(*) as count FROM telegrams WHERE citizenid = ? AND status = 0', {Player.PlayerData.citizenid}, function(result)
            local unreadCount = result and result[1] and result[1].count or 0
            unreadCount = tonumber(unreadCount) or 0
            TriggerClientEvent('rsg-telegram:client:updateUnreadCount', Player.PlayerData.source, unreadCount)
        end)
        
        -- Notify the recipient if they're online
        local targetPlayer = RSGCore.Functions.GetPlayerByCitizenId(telegram.recipient)
        if targetPlayer then
            TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, {
                title = "New Telegram Received",
                description = "You have received a telegram from the Sheriff's Office",
                type = 'inform',
                duration = 7000
            })
            
            -- Update their unread telegram count using rsg-telegram's system
            exports.oxmysql:execute('SELECT COUNT(*) as count FROM telegrams WHERE citizenid = ? AND status = 0', {telegram.recipient}, function(result)
                local unreadCount = result and result[1] and result[1].count or 0
                unreadCount = tonumber(unreadCount) or 0
                TriggerClientEvent('rsg-telegram:client:updateUnreadCount', targetPlayer.PlayerData.source, unreadCount)
            end)
        end
        
        cb(true)
    else
        print("Sheriff's Archives Server: Failed to send telegram")
        cb(false)
    end
end)