-- Criminal Record Client-side Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

------------------------------------------
-- View Criminal Record with Add Option
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewCriminalRecordWithAdd', function(data)
    local personData = data.personData
    local options = {}
    
    if personData.criminalRecord and #personData.criminalRecord > 0 then
        for i = 1, #personData.criminalRecord do
            local record = personData.criminalRecord[i]
            table.insert(options, {
                title = record.charges or 'Unknown charges',
                description = 'Date: ' .. (record.created_at or 'Unknown'),
                icon = 'fa-solid fa-scale-balanced',
                disabled = true
            })
        end
    else
        table.insert(options, {
            title = 'No criminal record',
            description = 'This person has no criminal history',
            icon = 'fa-solid fa-circle-info',
            disabled = true
        })
    end
    
    -- Add new criminal record option
    table.insert(options, {
        title = 'Add Criminal Record',
        description = 'Add a new criminal record for this person',
        icon = 'fa-solid fa-plus',
        event = 'rsg-lawman:client:addCriminalRecord',
        args = {citizenid = personData.playerData.citizenid},
        arrow = true
    })
    
    -- Back button
    table.insert(options, {
        title = 'Back',
        description = 'Return to person details',
        icon = 'fa-solid fa-arrow-left',
        event = 'rsg-lawman:client:viewPerson',
        args = {citizenid = personData.playerData.citizenid},
        arrow = true
    })
    
    lib.registerContext({
        id = 'mdt_criminal_record_with_add',
        title = 'Criminal Record',
        menu = 'mdt_person_details',
        options = options
    })
    
    lib.showContext('mdt_criminal_record_with_add')
end)

------------------------------------------
-- Add Criminal Record
------------------------------------------
RegisterNetEvent('rsg-lawman:client:addCriminalRecord', function(data)
    local citizenid = data.citizenid
    local input = lib.inputDialog('Add Criminal Record', {
        {type = 'textarea', label = 'Charges', description = 'Describe the criminal charges', required = true}
    })
    
    if input then
        local charges = input[1]
        
        if charges and charges ~= '' then
            local recordData = {
                citizenid = citizenid,
                charges = charges
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:createCriminalRecord', function(success)
                if success then
                    lib.notify({
                        title = 'Record Added',
                        description = 'Criminal record added successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to add criminal record',
                        type = 'error'
                    })
                end
                -- Refresh criminal record view
                TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
            end, recordData)
        else
            lib.notify({
                title = 'Error',
                description = 'Charges description is required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
        end
    else
        TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
    end
end)