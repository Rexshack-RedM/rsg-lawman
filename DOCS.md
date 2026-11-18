# rsg-lawman — Developer Docs

## ox_lib migration status (v3.1.0) — fully migrated, no ox_lib dependency
| Feature | Now uses | Status |
|---|---|---|
| Locales | `@rsg-core/shared/locale.lua` + `locale()` | migrated |
| Client notify | `RSGCore.Functions.Notify(data)` | migrated |
| Server notify | `TriggerClientEvent('RSGCore:Client:Notify', src, data)` | migrated |
| `cache.ped` | `PlayerPedId()` | migrated |
| Law office menu | built-in NUI (`html/`) via `openUI({ action = 'openMenu', ... })` | migrated |
| Jail time input | built-in NUI via `inputDialog(title, label)` (blocking, returns positive integer or nil) | migrated |

## NUI
- `html/index.html`, `style.css`, `script.js` — menu panel and numeric input modal in the house RDR2 style.
- NUI messages: `openMenu { title, subtitle, options[{id,title,description,icon,disabled}] }`, `openInput { title, label, confirm, cancel }`, `close`.
- NUI callbacks: `menuSelect { id }`, `inputSubmit { value|null }`, `close`. Menu actions run client-side from a local action table, so the NUI can't trigger arbitrary events. Jail time is still validated by the server.
- Esc closes, Enter confirms the input. Input accepts digits only.
- Focus goes through `applyNuiFocus()`, and push-to-talk stays usable (`Config.AllowPushToTalkWhileOpen`, `Config.PushToTalkControls`).

## Events
- `rsg-lawman:client:lawmanAlert (coords, text)` — map alert blip for on-duty `leo` job types.
- `rsg-lawman:client:getescorted (draggerSrc)` — attach/detach escorted player.

- `rsg-lawman:server:lawmanAlert (text, coords)` — sends an alert to on-duty `leo` players. Server-side: text must be a string (cut to 150 chars), at most one alert per player every 4s, and the position falls back to the sender's server-side position if missing or more than 250 units away.

## Commands
`/testalert`, `/searchplayer`, `/lawbadge`, `/jail <id> <time>`, `/unjail <id>`, `/cuff`, `/escort`.

## Locales
Keys live in `locales/*.json`. Required languages: en, de, el, es, fr, ja, nl, pl, pt-br, ro. `jail_player_header` takes the player id (`%s`).

## Changelog
- 3.1.0 — Replaced the ox_lib context menu and input dialog with built-in NUI; removed ox_lib entirely; added push-to-talk config; added `cl_confirm`/`cl_cancel` locale keys.
- 3.0.2 — Migrated locales, notifications and `cache.ped` to rsg-core; fixed server-side `lib.notify` call in escort (now notifies the officer); fixed malformed alert blip text; added ja, nl, ro locales and missing jail-dialog keys.

<!-- BEGIN AUTO-REFERENCE (generated from the code; re-run the generator instead of editing by hand) -->

## Technical reference

Generated from the source of **rsg-lawman 3.1.1**. Names, arguments and defaults below are read straight from the code.

### Dependencies

`rsg-core`

### Configuration

| Option | Default | Notes |
|---|---|---|
| `Config.Debug` | `false` | debug |
| `Config.AddGPSRoute` | `true` | settings |
| `Config.AlertTimer` | `60` |  |
| `Config.Keybind` | `'J'` |  |
| `Config.StorageMaxWeight` | `4000000` |  |
| `Config.StorageMaxSlots` | `50` |  |
| `Config.TrashCollection` | `1` | mins |
| `Config.ArmouryAccessGrade` | `1` | and greater than |
| `Config.SearchTime` | `10000` |  |
| `Config.SearchDistance` | `2.5` |  |
| `Config.EnablePlayerDeathAlerts` | `false` |  |
| `Config.EnableNPCDeathAlerts` | `false` |  |
| `Config.AlertCooldown` | `30000` |  |
| `Config.AlertDistance` | `100.0` |  |
| `Config.LawOfficeLocations` | `` | Law Office Prompt Locations |
| `Config.LawJobs` | `table` |  |
| `Config.AllowPushToTalkWhileOpen` | `true` | While NUI is open, block game controls but allow push-to-talk. |
| `Config.PushToTalkControls` | `table` |  |

### Callbacks

| Callback | Side | Arguments | File |
|---|---|---|---|
| `rsg-lawman:server:getlaw` | server | `source, cb` | `server/server.lua` |

```lua
-- client side
RSGCore.Functions.TriggerCallback('rsg-lawman:server:getlaw', function(result)
    -- use result
end)
```

### Events

Server events can be fired by any client, so every handler re-validates the player, the arguments and any permission, distance or cooldown on the server. Never add a reward to a handler without those checks.

| Event | Side | Arguments | File |
|---|---|---|---|
| `rsg-lawman:client:mainmenu` | client | `jobaccess, name` | `client/client.lua` |
| `rsg-lawman:client:openarmoury` | client | `` | `client/client.lua` |
| `rsg-lawman:client:jailplayer` | client | `playerId, time` | `client/client.lua` |
| `rsg-lawman:client:sendtojail` | client | `time` | `client/client.lua` |
| `rsg-lawman:client:lawmanAlert` | client | `coords, text` | `client/client.lua` |
| `rsg-lawman:client:cuffplayer` | client | `` | `client/client.lua` |
| `rsg-lawman:client:getcuffed` | client | `playerId, isSoftcuff` | `client/client.lua` |
| `rsg-lawman:client:escortplayer` | client | `` | `client/client.lua` |
| `rsg-lawman:client:getescorted` | client | `playerId` | `client/client.lua` |
| `rsg-lawman:client:lawbadge` | client | `` | `client/client.lua` |
| `rsg-lawman:client:searchplayer` | client | `` | `client/client.lua` |
| `rsg-lawman:client:openstorage` | client | `` | `client/client.lua` |
| `rsg-lawman:server:SearchPlayer` | server | `` | `server/server.lua` |
| `rsg-lawman:server:lawmanAlert` | server | `text, coords` | `server/server.lua` |
| `rsg-lawman:server:jailplayer` | server | `playerId, minutes` | `server/server.lua` |
| `rsg-lawman:server:cuffplayer` | server | `playerId, isSoftcuff` | `server/server.lua` |
| `rsg-lawman:server:sethandcuffstatus` | server | `isHandcuffed` | `server/server.lua` |
| `rsg-lawman:server:setescortstatus` | server | `isEscorted` | `server/server.lua` |
| `rsg-lawman:server:escortplayer` | server | `playerId` | `server/server.lua` |
| `rsg-lawman:server:storage` | server | `jobname` | `server/server.lua` |
| `rsg-lawman:server:updateoutlawstatus` | server | `amount, reason` | `server/server.lua` |

```lua
-- from a client script
TriggerServerEvent('rsg-lawman:server:SearchPlayer')
-- from a server script
TriggerClientEvent('rsg-lawman:client:mainmenu', source, jobaccess, name)
```

### Commands

| Command | Notes | File |
|---|---|---|
| `/testalert` | locale('sv_test') | `server/server.lua` |
| `/searchplayer` | locale('sv_searchplayer') | `server/server.lua` |
| `/lawbadge` | locale('sv_lawbadge') | `server/server.lua` |
| `/unjail` | locale('sv_unjail') | `server/server.lua` |
| `/jail` | locale('sv_jail') | `server/server.lua` |
| `/cuff` | locale('sv_cuff') | `server/server.lua` |
| `/escort` | locale('sv_escort') | `server/server.lua` |

### Useable items

`handcuffs`

### Locales

Language files in `locales/`: `cs`, `de`, `el`, `en`, `es`, `fr`, `it`, `ja`, `nl`, `pl`, `pt-br`, `ro`. Set the language with `setr rsg:locale "en"`.

<!-- END AUTO-REFERENCE -->
