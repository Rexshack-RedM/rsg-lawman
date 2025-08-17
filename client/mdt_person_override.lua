-- View Person Details (cu Bounty Alerts)
local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-lawman:client:viewPerson', function(data)
    local citizenid = data.citizenid
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getPersonDetails', function(personData)
        local options = {}
        
        -- Personal Information
        table.insert(options, {
            title = 'Personal Information',
            description = 'View citizen details',
            icon = 'fa-solid fa-user',
            event = 'rsg-lawman:client:viewPersonInfo',
            args = {personData = personData},
            arrow = true
        })
        
        -- Criminal Record
        table.insert(options, {
            title = 'Criminal Record',
            description = 'View criminal history',
            icon = 'fa-solid fa-gavel',
            event = 'rsg-lawman:client:viewCriminalRecord',
            args = {personData = personData},
            arrow = true
        })
        
        -- Citations
        table.insert(options, {
            title = 'Citations',
            description = 'View issued citations',
            icon = 'fa-solid fa-ticket',
            event = 'rsg-lawman:client:viewCitations',
            args = {personData = personData},
            arrow = true
        })
        
        -- Bounty Alerts
        table.insert(options, {
            title = 'Bounty Alerts',
            description = 'View bounty alerts for this person',
            icon = 'fa-solid fa-user-secret',
            event = 'rsg-lawman:client:viewPersonBountyAlerts',
            args = {citizenid = citizenid},
            arrow = true
        })
        
        -- Back button
        table.insert(options, {
            title = 'Back',
            description = 'Return to persons search',
            icon = 'fa-solid fa-arrow-left',
            event = 'rsg-lawman:client:openPersons',
            arrow = true
        })
        
        lib.registerContext({
            id = 'mdt_person_details',
            title = 'Person Details',
            menu = 'mdt_persons_results',
            options = options
        })
        
        lib.showContext('mdt_person_details')
    end, citizenid)
end)