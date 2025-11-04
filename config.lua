Config = {}

-- debug
Config.Debug = false

-- settings
Config.AddGPSRoute = true
Config.AlertTimer = 60
Config.Keybind = 'J'
Config.StorageMaxWeight = 4000000
Config.StorageMaxSlots = 50
Config.TrashCollection = 1    -- mins
Config.ArmouryAccessGrade = 1 -- and greater than
Config.SearchTime = 10000
Config.SearchDistance = 2.5
Config.EnablePlayerDeathAlerts = false
Config.EnableNPCDeathAlerts = false
Config.AlertCooldown = 30000
Config.AlertDistance = 100.0

-- Law Office Prompt Locations
Config.LawOfficeLocations =
{
    { -- valentine
        name = 'Valentine Sheriff',
        prompt = 'vallawoffice',
        coords = vector3(-278.42, 805.29, 119.38),
        jobaccess = 'nasheriff',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },

}

Config.LawJobs = {
    ['nasheriff'] = true,
}
