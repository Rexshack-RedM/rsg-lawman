-- View Citations
local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-lawman:client:viewCitations', function(data)
    TriggerEvent('rsg-lawman:client:viewCitationsWithPay', data)
end)