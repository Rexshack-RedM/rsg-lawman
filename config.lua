Config = {}

-- debug
Config.Debug = true

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
    } 
}
