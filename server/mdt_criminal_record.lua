-- Create Criminal Record
local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']

RSGCore.Functions.CreateCallback('rsg-lawman:server:createCriminalRecord', function(source, cb, recordData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Verificăm dacă ofițerul are permisiunea să adauge înregistrări criminale
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Validăm datele
    if not recordData.citizenid or not recordData.charges or recordData.charges == '' then
        cb(false)
        return
    end
    
    -- Inserăm înregistrarea criminală
    local insertId = MySQL.insert.await([[
        INSERT INTO mdt_criminal_records (citizenid, charges, officer_id, created_at)
        VALUES (?, ?, ?, NOW())
    ]], { 
        recordData.citizenid, 
        recordData.charges, 
        Player.PlayerData.citizenid 
    })
    
    if insertId then
        -- Actualizăm metadata jucătorului pentru a indica că are un record criminal
        local OtherPlayer = RSGCore.Functions.GetPlayerByCitizenId(recordData.citizenid)
        if OtherPlayer then
            local currentDate = os.date('%Y-%m-%d')
            OtherPlayer.Functions.SetMetaData('criminalrecord', { 
                ['hasRecord'] = true, 
                ['date'] = currentDate 
            })
        else
            -- Dacă jucătorul nu este online, actualizăm direct în baza de date
            MySQL.update.await([[
                UPDATE players 
                SET metadata = JSON_SET(metadata, '$.criminalrecord.hasRecord', true, '$.criminalrecord.date', ?)
                WHERE citizenid = ?
            ]], { os.date('%Y-%m-%d'), recordData.citizenid })
        end
        
        -- Logăm acțiunea
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'criminal_record_created', 
            'Created criminal record for: ' .. recordData.citizenid .. ' - Charges: ' .. recordData.charges,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)