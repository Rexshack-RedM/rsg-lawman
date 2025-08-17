local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports['oxmysql']
lib.locale()

------------------------------------------
-- MDT Callbacks
------------------------------------------

-- Get MDT Data
RSGCore.Functions.CreateCallback('rsg-lawman:server:getMDTData', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Get recent incidents, warrants, bolos
    local recentIncidents = MySQL.query.await([[
        SELECT * FROM mdt_incidents 
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) 
        ORDER BY created_at DESC 
        LIMIT 10
    ]])
    
    local activeWarrants = MySQL.query.await([[
        SELECT * FROM mdt_warrants 
        WHERE status = 'active' 
        ORDER BY created_at DESC 
        LIMIT 10
    ]])
    
    local activeBolos = MySQL.query.await([[
        SELECT * FROM mdt_bolos 
        WHERE status = 'active' 
        ORDER BY created_at DESC 
        LIMIT 10
    ]])
    
    local myReports = MySQL.query.await([[
        SELECT * FROM mdt_reports 
        WHERE officer_id = ? 
        ORDER BY created_at DESC 
        LIMIT 10
    ]], {Player.PlayerData.citizenid})
    
    cb({
        recentIncidents = recentIncidents,
        activeWarrants = activeWarrants,
        activeBolos = activeBolos,
        myReports = myReports
    })
end)

-- Search Persons
RSGCore.Functions.CreateCallback('rsg-lawman:server:searchPersons', function(source, cb, query)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    local results = MySQL.query.await([[
        SELECT citizenid, charinfo, metadata 
        FROM players 
        WHERE citizenid LIKE ? OR charinfo LIKE ? 
        LIMIT 20
    ]], { '%' .. query .. '%', '%' .. query .. '%' })
    
    cb(results)
end)

-- Search Vehicles
RSGCore.Functions.CreateCallback('rsg-lawman:server:searchVehicles', function(source, cb, query)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    local results = MySQL.query.await([[
        SELECT * FROM mdt_vehicles 
        WHERE plate LIKE ? OR model LIKE ? OR owner LIKE ? 
        LIMIT 20
    ]], { '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%' })
    
    cb(results)
end)

-- Search Horses
RSGCore.Functions.CreateCallback('rsg-lawman:server:searchHorses', function(source, cb, query)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Search horses in player_horses table (RSG Horses system)
    local horses = MySQL.query.await([[
        SELECT * FROM player_horses 
        WHERE horseid LIKE ? OR name LIKE ? OR citizenid LIKE ? 
        LIMIT 20
    ]], { '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%' })
    
    cb(horses)
end)

-- Get Person Details
RSGCore.Functions.CreateCallback('rsg-lawman:server:getPersonDetails', function(source, cb, citizenid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Get player data
    local playerData = MySQL.single.await([[
        SELECT citizenid, charinfo, metadata 
        FROM players 
        WHERE citizenid = ?
    ]], { citizenid })
    
    if not playerData then
        cb({})
        return
    end
    
    -- Get criminal record
    local criminalRecord = MySQL.query.await([[
        SELECT * FROM mdt_criminal_records 
        WHERE citizenid = ? 
        ORDER BY created_at DESC
    ]], { citizenid })
    
    -- Get warrants
    local warrants = MySQL.query.await([[
        SELECT * FROM mdt_warrants 
        WHERE citizenid = ? 
        ORDER BY created_at DESC
    ]], { citizenid })
    
    -- Get citations
    local citations = MySQL.query.await([[
        SELECT * FROM mdt_citations 
        WHERE citizenid = ? 
        ORDER BY created_at DESC
    ]], { citizenid })
    
    -- Get incidents
    local incidents = MySQL.query.await([[
        SELECT * FROM mdt_incidents 
        WHERE involved_persons LIKE ? 
        ORDER BY created_at DESC
    ]], { '%' .. citizenid .. '%' })
    
    cb({
        playerData = playerData,
        criminalRecord = criminalRecord,
        warrants = warrants,
        citations = citations,
        incidents = incidents
    })
end)

-- Get Vehicle Details
RSGCore.Functions.CreateCallback('rsg-lawman:server:getVehicleDetails', function(source, cb, plate)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Get vehicle data
    local vehicleData = MySQL.single.await([[
        SELECT * FROM mdt_vehicles 
        WHERE plate = ?
    ]], { plate })
    
    if not vehicleData then
        cb({})
        return
    end
    
    -- Get incidents
    local incidents = MySQL.query.await([[
        SELECT * FROM mdt_incidents 
        WHERE involved_vehicles LIKE ? 
        ORDER BY created_at DESC
    ]], { '%' .. plate .. '%' })
    
    cb({
        vehicleData = vehicleData,
        incidents = incidents
    })
end)

-- Get Horse Details
RSGCore.Functions.CreateCallback('rsg-lawman:server:getHorseDetails', function(source, cb, horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Get horse data from player_horses table
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

-- Get Horse Bounty Alerts
RSGCore.Functions.CreateCallback('rsg-lawman:server:getHorseBountyAlerts', function(source, cb, horseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb({})
        return
    end
    
    -- Get bounty alerts for this horse
    local alerts = MySQL.query.await([[
        SELECT * FROM mdt_bounty_alerts 
        WHERE target_citizenid = ? 
        ORDER BY created_at DESC
    ]], { horseid })
    
    cb(alerts)
end)

-- Save Person
RSGCore.Functions.CreateCallback('rsg-lawman:server:savePerson', function(source, cb, person)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Update person data
    local success = MySQL.update.await([[
        UPDATE players 
        SET charinfo = ?, metadata = ? 
        WHERE citizenid = ?
    ]], { json.encode(person.charinfo), json.encode(person.metadata), person.citizenid })
    
    if success then
        -- Log the update
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'person_update', 
            'Updated person profile: ' .. person.citizenid,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)

-- Save Vehicle
RSGCore.Functions.CreateCallback('rsg-lawman:server:saveVehicle', function(source, cb, vehicle)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Update vehicle data
    local success = MySQL.update.await([[
        UPDATE mdt_vehicles 
        SET owner = ?, model = ?, color = ?, notes = ? 
        WHERE plate = ?
    ]], { 
        vehicle.owner, 
        vehicle.model, 
        vehicle.color, 
        vehicle.notes, 
        vehicle.plate 
    })
    
    if success then
        -- Log the update
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'vehicle_update', 
            'Updated vehicle: ' .. vehicle.plate,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)

-- Create Warrant
RSGCore.Functions.CreateCallback('rsg-lawman:server:createWarrant', function(source, cb, warrant)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Insert warrant
    local insertId = MySQL.insert.await([[
        INSERT INTO mdt_warrants (citizenid, reason, issued_by, status, created_at)
        VALUES (?, ?, ?, 'active', NOW())
    ]], { 
        warrant.citizenid, 
        warrant.reason, 
        Player.PlayerData.citizenid 
    })
    
    if insertId then
        -- Log the creation
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'warrant_created', 
            'Created warrant for: ' .. warrant.citizenid,
            Player.PlayerData.citizenid
        })
        
        -- Notify other officers
        local players = RSGCore.Functions.GetRSGPlayers()
        for _, v in pairs(players) do
            if v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
                TriggerClientEvent('ox_lib:notify', v.PlayerData.source, {
                    title = locale('sv_warrant_created'),
                    description = locale('sv_warrant_for') .. warrant.citizenid,
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

-- Create Report
RSGCore.Functions.CreateCallback('rsg-lawman:server:createReport', function(source, cb, report)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Insert report
    local insertId = MySQL.insert.await([[
        INSERT INTO mdt_reports (title, description, officer_id, location, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { 
        report.title, 
        report.description, 
        Player.PlayerData.citizenid,
        json.encode(report.location)
    })
    
    if insertId then
        -- Log the creation
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'report_created', 
            'Created report: ' .. report.title,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)

-- Create Citation
RSGCore.Functions.CreateCallback('rsg-lawman:server:createCitation', function(source, cb, citation)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.type ~= 'leo' then
        cb(false)
        return
    end
    
    -- Insert citation
    local insertId = MySQL.insert.await([[
        INSERT INTO mdt_citations (citizenid, reason, amount, officer_id, status, created_at)
        VALUES (?, ?, ?, ?, 'unpaid', NOW())
    ]], { 
        citation.citizenid, 
        citation.reason, 
        citation.amount, 
        Player.PlayerData.citizenid 
    })
    
    if insertId then
        -- Log the creation
        MySQL.insert.await([[
            INSERT INTO mdt_logs (log_type, description, officer_id, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { 
            'citation_created', 
            'Created citation for: ' .. citation.citizenid,
            Player.PlayerData.citizenid
        })
        
        cb(true)
    else
        cb(false)
    end
end)

------------------------------------------
-- MDT Commands
------------------------------------------

RSGCore.Commands.Add('mdt', locale('sv_mdt'), {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.type == 'leo' then
        TriggerClientEvent('rsg-lawman:client:openMDT', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('cl_only_law'),
            type = 'error',
            duration = 5000
        })
    end
end)