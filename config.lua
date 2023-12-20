Config = {}

-- debug
Config.Debug = false

-- law office blip settings
Config.LawOfficeBlip = {
    blipName = 'Law Office', -- Config.Blip.blipName
    blipSprite = 'blip_ambient_sheriff', -- Config.Blip.blipSprite
    blipScale = 0.2 -- Config.Blip.blipScale
}

-- settings
Config.AddGPSRoute = true
Config.AlertTimer = 60
Config.Keybind = 'J'

-- Law Office Prompt Locations
Config.LawOfficeLocations =
{
    {   -- valentine
        name = 'Lawman Office',
        prompt = 'vallawoffice',
        coords = vector3(-278.42, 805.29, 119.38),
        jobaccess = 'vallaw',
        showblip = true
    },
    {   -- rhodes
        name = 'Lawman Office',
        prompt = 'rholawoffice',
        coords = vector3(1362.04, -1302.10, 77.77),
        jobaccess = 'rholaw',
        showblip = true
    },
    {   -- blackwater
        name = 'Lawman Office',
        prompt = 'blklawoffice',
        coords = vector3(-761.76, -1268.18, 44.04),
        jobaccess = 'blklaw',
        showblip = true
    },
    {   -- strawberry
        name = 'Lawman Office',
        prompt = 'strlawoffice',
        coords = vector3(-1811.95, -353.94, 164.65),
        jobaccess = 'strlaw',
        showblip = true
    },
    {   -- saint denis
        name = 'Lawman Office',
        prompt = 'stdenlawoffice',
        coords = vector3(2507.72, -1301.89, 48.95),
        jobaccess = 'stdenlaw',
        showblip = true
    },
}

Config.LawJobs = { 'vallaw' , 'rholaw', 'blklaw', 'strlaw', 'stdenlaw' }

Config.LawOfficeArmoury = {
    [1] = { name = "weapon_revolver_cattleman",  price = 0, amount = 10, info = {}, type = "weapon", slot = 1, },
    [2] = { name = "weapon_repeater_winchester", price = 0, amount = 10, info = {}, type = "weapon", slot = 2, },
    [3] = { name = "weapon_melee_lantern",       price = 0, amount = 10, info = {}, type = "weapon", slot = 3, },
    [4] = { name = "weapon_lasso_reinforced",    price = 0, amount = 10, info = {}, type = "weapon", slot = 4, },
    [5] = { name = "ammo_revolver",              price = 0, amount = 50, info = {}, type = "item",   slot = 5, },
    [6] = { name = "ammo_repeater",              price = 0, amount = 50, info = {}, type = "item",   slot = 6, },
}