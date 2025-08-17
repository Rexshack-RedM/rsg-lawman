-- Pay Citation (adăugat pentru funcționalitatea de plată)
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']

RSGCore.Functions.CreateCallback('rsg-lawman:server:payCitation', function(source, cb, citationId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    -- Get citation details
    local citation = MySQL.single.await([[
        SELECT * FROM mdt_citations 
        WHERE id = ? AND citizenid = ?
    ]], { citationId, Player.PlayerData.citizenid })
    
    if not citation then
        cb(false)
        return
    end
    
    -- Check if already paid
    if citation.status == 'paid' then
        cb(false)
        return
    end
    
    -- Check if player has enough money
    local playerMoney = Player.Functions.GetMoney('cash')
    if playerMoney < citation.amount then
        -- Check bank if not enough cash
        local bankMoney = Player.Functions.GetMoney('bank')
        if (playerMoney + bankMoney) < citation.amount then
            cb(false)
            return
        end
    end
    
    -- Deduct money (cash first, then bank if needed)
    local remainingAmount = citation.amount
    if playerMoney >= remainingAmount then
        Player.Functions.RemoveMoney('cash', remainingAmount)
        remainingAmount = 0
    else
        Player.Functions.RemoveMoney('cash', playerMoney)
        remainingAmount = remainingAmount - playerMoney
        if remainingAmount > 0 then
            Player.Functions.RemoveMoney('bank', remainingAmount)
        end
    end
    
    -- Update citation status
    local success = MySQL.update.await([[
        UPDATE mdt_citations 
        SET status = 'paid', updated_at = NOW()
        WHERE id = ?
    ]], { citationId })
    
    if success then
        -- Log the payment
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'citation_paid', 
            'Paid citation #' .. citationId .. ' for: ' .. Player.PlayerData.citizenid,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        -- Refund money if update failed
        Player.Functions.AddMoney('cash', citation.amount)
        cb(false)
    end
end)