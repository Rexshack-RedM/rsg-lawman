-- Bounty Alerts Server Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']
lib.locale()

------------------------------------------
-- Create Bounty Alert
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:createBountyAlert', function(source, cb, alertData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Verificăm dacă ofițerul are permisiunea să creeze bounty alerts
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Validăm datele
    if not alertData.target_citizenid or not alertData.reason or alertData.reason == '' then
        cb(false)
        return
    end
    
    -- Inserăm bounty alert cu parametri corecți
    local query = [[
        INSERT INTO mdt_bounty_alerts (target_citizenid, reason, reward, issued_by, status, created_at]]
    
    local params = {
        alertData.target_citizenid,
        alertData.reason,
        tonumber(alertData.reward) or 0,
        Player.PlayerData.citizenid
    }
    
    -- Adăugăm expirare dacă este specificată
    if alertData.expires_in_days and tonumber(alertData.expires_in_days) > 0 then
        query = query .. ", expires_at) VALUES (?, ?, ?, ?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL ? DAY))"
        table.insert(params, tonumber(alertData.expires_in_days))
    else
        query = query .. ") VALUES (?, ?, ?, ?, 'active', NOW())"
    end
    
    local insertId = MySQL.insert.await(query, params)
    
    if insertId then
        -- Logăm acțiunea
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'bounty_alert_created', 
            'Created bounty alert for: ' .. alertData.target_citizenid .. ' - Reward: $' .. (tonumber(alertData.reward) or 0),
            Player.PlayerData.citizenid
        })
        
        -- Notificăm ofițerii online
        local players = RSGCore.Functions.GetRSGPlayers()
        for _, v in pairs(players) do
            if v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
                TriggerClientEvent('ox_lib:notify', v.PlayerData.source, {
                    title = 'New Bounty Alert',
                    description = 'Bounty alert issued for citizen ' .. alertData.target_citizenid,
                    type = 'inform',
                    duration = 7000
                })
            end
        end
        
        cb(true)
    else
        cb(false)
    end
end)

------------------------------------------
-- Get Active Bounty Alerts
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getActiveBountyAlerts', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Obținem bounty alerts active care nu au expirat
    local alerts = MySQL.query.await([[
        SELECT ba.*, p.charinfo 
        FROM mdt_bounty_alerts ba
        LEFT JOIN players p ON ba.target_citizenid = p.citizenid
        WHERE ba.status = 'active' AND (ba.expires_at IS NULL OR ba.expires_at > NOW())
        ORDER BY ba.created_at DESC
        LIMIT 50
    ]])
    
    cb(alerts)
end)

------------------------------------------
-- Get Person Bounty Alerts
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getPersonBountyAlerts', function(source, cb, citizenid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Obținem bounty alerts pentru o persoană specifică
    local alerts = MySQL.query.await([[
        SELECT * FROM mdt_bounty_alerts 
        WHERE target_citizenid = ? 
        ORDER BY created_at DESC
    ]], { citizenid })
    
    cb(alerts)
end)

------------------------------------------
-- Claim Bounty Alert
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:claimBountyAlert', function(source, cb, alertId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    -- Obținem detaliile bounty alert-ului
    local alert = MySQL.single.await([[
        SELECT * FROM mdt_bounty_alerts 
        WHERE id = ? AND status = 'active'
    ]], { alertId })
    
    if not alert then
        cb(false)
        return
    end
    
    -- Verificăm dacă alerta nu a expirat
    if alert.expires_at then
        local expiresAtTime = alert.expires_at
        local currentTime = os.time()
        if expiresAtTime < currentTime then
            -- Marchează alerta ca expirată
            MySQL.update.await([[
                UPDATE mdt_bounty_alerts 
                SET status = 'expired', updated_at = NOW()
                WHERE id = ?
            ]], { alertId })
            cb(false)
            return
        end
    end
    
    -- Actualizăm bounty alert-ul ca fiind revendicat
    local success = MySQL.update.await([[
        UPDATE mdt_bounty_alerts 
        SET status = 'claimed', claimed_by = ?, updated_at = NOW()
        WHERE id = ?
    ]], { Player.PlayerData.citizenid, alertId })
    
    if success then
        -- Dăm recompensa jucătorului
        if alert.reward > 0 then
            Player.Functions.AddMoney('bank', alert.reward)
            
            -- Notificăm jucătorul
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Bounty Claimed',
                description = 'You claimed a bounty reward of $' .. alert.reward,
                type = 'success',
                duration = 5000
            })
        end
        
        -- Logăm acțiunea
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'bounty_alert_claimed', 
            'Bounty alert #' .. alertId .. ' claimed by ' .. Player.PlayerData.citizenid .. ' for target ' .. alert.target_citizenid,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)

------------------------------------------
-- Update Bounty Alert Status
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:updateBountyAlertStatus', function(source, cb, alertId, status)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Actualizăm statusul bounty alert-ului
    local success = MySQL.update.await([[
        UPDATE mdt_bounty_alerts 
        SET status = ?, updated_at = NOW()
        WHERE id = ?
    ]], { status, alertId })
    
    if success then
        -- Logăm acțiunea
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'bounty_alert_updated', 
            'Bounty alert #' .. alertId .. ' status updated to ' .. status .. ' by ' .. Player.PlayerData.citizenid,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)