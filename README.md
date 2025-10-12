<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# ⭐ rsg-lawman
**Law enforcement and sheriff management system for RedM using RSG Core.**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

> Full-featured law enforcement framework for RedM built on RSG Core.  
> Provides arrest, search, alerts, and law office management systems with ox_lib menus and configurable prompts.

---

## 🛠️ Dependencies
- [**rsg-core**](https://github.com/Rexshack-RedM/rsg-core) 🤠
- [**ox_lib**](https://github.com/Rexshack-RedM/ox_lib) ⚙️ *(for menus and notifications)*
- [**oxmysql**](https://github.com/overextended/oxmysql) 🗄️ *(for database storage)*
- [**rsg-inventory**](https://github.com/Rexshack-RedM/rsg-inventory) 🎒 *(for player search & confiscation)*

**Interaction:** Prompts are automatically created at each law office defined in `Config.LawOfficeLocations`.  
**Keybind:** Default interaction key = `'J'`.  
**Locales:** `locales/en.json, fr.json, es.json, it.json, el.json, pt-br.json` (loaded via `lib.locale()`).

---

## ✨ Features (detailed)

### 🧭 Law Office Menu
- Context-based menu using **ox_lib** for players with a **law job** (e.g., `vallaw`, `rholaw`, `blklaw`).
- Access is restricted to **on-duty lawmen**.
- Opened through prompts created at configured coordinates.

### 👮 Law Tools
- **Search Player Inventory**
  - Command: `/searchplayer`
  - Opens a player’s inventory and allows confiscation of items.
- **Crime Alerts**
  - Command: `/testalert` (debug/test command).
  - Triggers a **map alert** for nearby lawmen.
  - Alerts can originate from player or NPC deaths (configurable).
- **Lawman Alert System**
  - Sends real-time alerts to on-duty lawmen with coordinates and context.
  - Customizable cooldown, distance, and timer values in config.

### 🔫 Storage & Armoury
- Shared stash per law office.
- `Config.StorageMaxWeight` and `Config.StorageMaxSlots` define stash capacity.
- `Config.ArmouryAccessGrade` determines minimum grade required for access.

### 🧩 Configuration Highlights
```lua
Config.AddGPSRoute = true
Config.AlertTimer = 60
Config.Keybind = 'J'
Config.StorageMaxWeight = 4000000
Config.StorageMaxSlots = 50
Config.TrashCollection = 1
Config.ArmouryAccessGrade = 1
Config.SearchTime = 10000
Config.SearchDistance = 2.5
Config.EnablePlayerDeathAlerts = false
Config.EnableNPCDeathAlerts = false
Config.AlertCooldown = 30000
Config.AlertDistance = 100.0
```

### 🗺️ Law Office Locations
Example from `config.lua`:
```lua
Config.LawOfficeLocations = {
    {
        name = 'Lawman Office',
        prompt = 'vallawoffice',
        coords = vector3(-278.42, 805.29, 119.38),
        jobaccess = 'vallaw',
        blipsprite = 'blip_ambient_sheriff',
        blipscale = 0.2,
        showblip = true
    },
}
```

---

## 📸 Preview
*(soon)*

---

## 📂 Installation
1. Place `rsg-lawman` inside your `resources/[rsg]` folder.
2. Ensure **rsg-core**, **ox_lib**, **rsg-inventory**, and **oxmysql** are installed.
3. Adjust settings and locations in `config.lua`.
4. Add to your `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure rsg-core
   ensure rsg-inventory
   ensure rsg-lawman
   ```
5. Restart your server.

---

## 🔐 Permissions
- Accessible only to players with valid **law jobs** (e.g., `vallaw`, `rholaw`, etc.).  
- Armoury and stash access require grade ≥ `Config.ArmouryAccessGrade`.  
- Alerts and search actions are restricted to law officers.

---

## 🌍 Locales
Provided in `locales/`: `en`, `fr`, `es`, `it`, `el`, `pt-br`.  
Fully localized prompts, menus, and notifications.

---

## 💎 Credits
- **RSG / Rexshack-RedM** and contributors  
- Community testers and translators  
- License: GPL‑3.0  

