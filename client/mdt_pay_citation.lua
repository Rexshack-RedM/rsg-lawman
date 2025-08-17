-- Pay Citation Client-side Functions
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

------------------------------------------
-- View Citations with Pay Option
------------------------------------------
RegisterNetEvent('rsg-lawman:client:viewCitationsWithPay', function(data)
    local personData = data.personData
    local options = {}
    
    if personData.citations and #personData.citations > 0 then
        for i = 1, #personData.citations do
            local citation = personData.citations[i]
            local status = citation.status or 'unknown'
            local statusIcon = 'fa-solid fa-question'
            local isPayable = false
            
            if status == 'paid' then
                statusIcon = 'fa-solid fa-check'
            elseif status == 'unpaid' then
                statusIcon = 'fa-solid fa-clock'
                isPayable = true
            elseif status == 'overdue' then
                statusIcon = 'fa-solid fa-exclamation'
                isPayable = true
            end
            
            -- Add citation info
            table.insert(options, {
                title = citation.reason or 'Unknown reason',
                description = 'Amount: $' .. (citation.amount or '0') .. ' | Status: ' .. status,
                icon = statusIcon,
                disabled = true
            })
            
            -- Add pay button if citation is payable
            if isPayable then
                table.insert(options, {
                    title = 'Pay Citation',
                    description = 'Pay this citation ($' .. (citation.amount or '0') .. ')',
                    icon = 'fa-solid fa-money-bill',
                    event = 'rsg-lawman:client:payCitation',
                    args = {citationId = citation.id, amount = citation.amount, citizenid = personData.playerData.citizenid},
                    arrow = true
                })
            end
        end
    else
        table.insert(options, {
            title = 'No citations',
            description = 'This person has no citations',
            icon = 'fa-solid fa-circle-info',
            disabled = true
        })
    end
    
    -- Issue new citation option
    table.insert(options, {
        title = 'Issue Citation',
        description = 'Issue a new citation to this person',
        icon = 'fa-solid fa-plus',
        event = 'rsg-lawman:client:issueCitation',
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
        id = 'mdt_citations_with_pay',
        title = 'Citations',
        menu = 'mdt_person_details',
        options = options
    })
    
    lib.showContext('mdt_citations_with_pay')
end)

------------------------------------------
-- Pay Citation
------------------------------------------
RegisterNetEvent('rsg-lawman:client:payCitation', function(data)
    local citationId = data.citationId
    local amount = data.amount
    local citizenid = data.citizenid
    
    local alert = lib.alertDialog({
        header = 'Confirm Payment',
        content = 'Are you sure you want to pay this citation for $' .. amount .. '?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        RSGCore.Functions.TriggerCallback('rsg-lawman:server:payCitation', function(success)
            if success then
                lib.notify({
                    title = 'Payment Successful',
                    description = 'Citation paid successfully',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Payment Failed',
                    description = 'Insufficient funds or payment error',
                    type = 'error'
                })
            end
            -- Refresh citations view
            TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
        end, citationId)
    else
        -- Return to citations view
        TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
    end
end)