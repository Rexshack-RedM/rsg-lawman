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

## Commands
`/testalert`, `/searchplayer`, `/lawbadge`, `/jail <id> <time>`, `/unjail <id>`, `/cuff`, `/escort`.

## Locales
Keys live in `locales/*.json`. Required languages: en, de, el, es, fr, ja, nl, pl, pt-br, ro. `jail_player_header` takes the player id (`%s`).

## Changelog
- 3.1.0 — Replaced the ox_lib context menu and input dialog with built-in NUI; removed ox_lib entirely; added push-to-talk config; added `cl_confirm`/`cl_cancel` locale keys.
- 3.0.2 — Migrated locales, notifications and `cache.ped` to rsg-core; fixed server-side `lib.notify` call in escort (now notifies the officer); fixed malformed alert blip text; added ja, nl, ro locales and missing jail-dialog keys.
