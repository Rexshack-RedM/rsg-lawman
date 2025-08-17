-- Horses Server Functions for Sheriff Archives
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']

------------------------------------------
-- Search Horses
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:searchHorses', function(source, cb, query)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Căutăm cai în tabela player_horses (sistemul RSG Horses)
    local horses = MySQL.query.await([[
        SELECT * FROM player_horses 
        WHERE horseid LIKE ? OR name LIKE ? OR citizenid LIKE ? 
        LIMIT 20
    ]], { '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%' })
    
    cb(horses)
end)

------------------------------------------
-- Get Horse Details
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getHorseDetails', function(source, cb, horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Obținem datele calului
    local horseData = MySQL.single.await([[
        SELECT * FROM player_horses 
        WHERE horseid = ?
    ]], { horseid })
    
    if not horseData then
        cb({})
        return
    end
    
    cb({
        horseData = horseData
    })
end)

------------------------------------------
-- Get Horse Bounty Alerts
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-lawman:server:getHorseBountyAlerts', function(source, cb, horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Obținem bounty alerts pentru acest cal
    local alerts = MySQL.query.await([[
        SELECT * FROM mdt_bounty_alerts 
        WHERE target_citizenid = ? 
        ORDER BY created_at DESC
    ]], { horseid })
    
    cb(alerts)
end)