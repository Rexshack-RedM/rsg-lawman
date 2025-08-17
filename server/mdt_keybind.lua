-- Add this to the bottom of server/mdt.lua

------------------------------------------
-- MDT Keybind Access Check
------------------------------------------
RegisterNetEvent('rsg-lawman:server:checkMDTAccess', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.job.type == 'leo' then
        TriggerClientEvent('rsg-lawman:client:openMDTFromKeybind', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('cl_only_law'),
            type = 'error',
            duration = 5000
        })
    end
end)