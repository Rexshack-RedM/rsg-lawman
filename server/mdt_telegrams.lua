-- Telegrams Server Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']

------------------------------------------
-- Get Telegrams for Player
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getTelegrams', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb({})
        return
    end
    
    -- Get telegrams for this player
    local telegrams = MySQL.query.await([[
        SELECT id, citizenid, recipient, sender, sendername, subject, sentDate, message, status
        FROM telegrams 
        WHERE citizenid = ? 
        ORDER BY sentDate DESC 
        LIMIT 50
    ]], { Player.PlayerData.citizenid })
    
    cb(telegrams)
end)

------------------------------------------
-- Mark Telegram as Read
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:markTelegramAsRead', function(source, cb, telegramId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    -- Verify that this telegram belongs to the player
    local telegram = MySQL.single.await([[
        SELECT * FROM telegrams 
        WHERE id = ? AND citizenid = ?
    ]], { telegramId, Player.PlayerData.citizenid })
    
    if not telegram then
        cb(false)
        return
    end
    
    -- Mark as read
    local success = MySQL.update.await([[
        UPDATE telegrams 
        SET status = '1' 
        WHERE id = ?
    ]], { telegramId })
    
    if success then
        -- Update unread count
        exports.oxmysql:execute([[
            SELECT COUNT(*) as count 
            FROM telegrams 
            WHERE citizenid = ? AND status = '0'
        ]], { Player.PlayerData.citizenid }, function(result)
            local unreadCount = result and result[1] and result[1].count or 0
            unreadCount = tonumber(unreadCount) or 0
            TriggerClientEvent('rsg-telegram:client:updateUnreadCount', src, unreadCount)
        end)
        
        cb(true)
    else
        cb(false)
    end
end)

------------------------------------------
-- Reply to Telegram (already implemented in mdt_send_telegram.lua)
-- We'll just add the callback here for completeness
------------------------------------------
-- The sendTelegram callback is already implemented in mdt_send_telegram.lua
-- We don't need to duplicate it here