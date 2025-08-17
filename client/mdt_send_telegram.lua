------------------------------------------
-- Send Telegram
------------------------------------------
local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-lawman:client:sendTelegram', function(data)
    local citizenid = data.citizenid
    
    local input = lib.inputDialog('Send Telegram', {
        {type = 'input', label = 'Subject', description = 'Telegram subject', required = true},
        {type = 'textarea', label = 'Message', description = 'Telegram message', required = true}
    })
    
    if input then
        local subject = input[1]
        local message = input[2]
        
        if subject and subject ~= '' and message and message ~= '' then
            local telegram = {
                recipient = citizenid,
                subject = subject,
                message = message
            }
            
            RSGCore.Functions.TriggerCallback('rsg-lawman:server:sendTelegram', function(success)
                if success then
                    lib.notify({
                        title = 'Telegram Sent',
                        description = 'Telegram sent successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Failed to send telegram',
                        type = 'error'
                    })
                end
                -- Return to person view
                TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
            end, telegram)
        else
            lib.notify({
                title = 'Error',
                description = 'Subject and message are required',
                type = 'error'
            })
            TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
        end
    else
        TriggerEvent('rsg-lawman:client:viewPerson', {citizenid = citizenid})
    end
end)