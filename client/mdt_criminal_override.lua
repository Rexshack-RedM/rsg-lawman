-- View Criminal Record
local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-lawman:client:viewCriminalRecord', function(data)
    TriggerEvent('rsg-lawman:client:viewCriminalRecordWithAdd', data)
end)