Config = {}

-- debug
Config.Debug = false

-- settings
Config.AddGPSRoute = true
Config.AlertTimer = 60
Config.Keybind = 'J'
Config.StorageMaxWeight = 4000000
Config.StorageMaxSlots = 50
Config.TrashCollection = 1 -- mins
Config.ArmouryAccessGrade = 1 -- and greater than
Config.SearchTime = 10000
Config.SearchDistance = 2.5

-- Law Office Prompt Locations
Config.LawOfficeLocations =
{
    {   -- valentine
        name = 'Lawman Office',
        prompt = 'vallawoffice',
        coords = vector3(-278.42, 805.29, 119.38),
        jobaccess = 'vallaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
    {   -- rhodes
        name = 'Lawman Office',
        prompt = 'rholawoffice',
        coords = vector3(1362.04, -1302.10, 77.77),
        jobaccess = 'rholaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
    {   -- blackwater
        name = 'Lawman Office',
        prompt = 'blklawoffice',
        coords = vector3(-761.76, -1268.18, 44.04),
        jobaccess = 'blklaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
    {   -- strawberry
        name = 'Lawman Office',
        prompt = 'strlawoffice',
        coords = vector3(-1811.95, -353.94, 164.65),
        jobaccess = 'strlaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
    {   -- saint denis
        name = 'Lawman Office',
        prompt = 'stdenlawoffice',
        coords = vector3(2507.72, -1301.89, 48.95),
        jobaccess = 'stdenlaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
}

Config.LawJobs = { 'vallaw' , 'rholaw', 'blklaw', 'strlaw', 'stdenlaw' }
