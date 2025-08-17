# rsg-lawman

## Law Enforcement Resource for RSG Framework

rsg-lawman is a comprehensive law enforcement resource for RedM servers using the RSG Framework. It provides essential tools and systems for law enforcement officers to maintain order in the Wild West.

## Features

- **Law Office Locations**: Multiple law office locations with interactive prompts
- **Duty System**: Toggle on/off duty status
- **Armoury**: Access to weapons and equipment (rank-restricted)
- **Handcuffing System**: Restrain suspects with soft or hard cuffs
- **Escort System**: Escort restrained suspects
- **Jailing System**: Send criminals to jail for specified times
- **Law Badge**: Equip/unequip law enforcement badge
- **Search System**: Search players and their inventories
- **Alert System**: Receive notifications for player/NPC deaths
- **Sheriffs Archives Terminal (SA)**: Comprehensive database system for criminal records, warrants, BOLOs, and more

## Installation

1. Ensure you have RSG Framework installed
2. Add `rsg-lawman` to your resources folder
3. Add `ensure rsg-lawman` to your server.cfg
4. Run the SQL schema to create necessary database tables
5. Configure the resource in `config.lua` as needed
6. Restart your server

## Dependencies

- rsg-core
- ox_lib
- rsg-inventory
- rsg-prison
- rsg-bossmenu
- rsg-shops

## Commands

- `/testalert` - Send a test alert to all on-duty officers
- `/searchplayer` - Search another player's inventory
- `/lawbadge` - Equip/unequip law enforcement badge
- `/unjail [id]` - Release a player from jail (law only)
- `/jail [id] [time]` - Jail a player for specified time (law only)
- `/cuff` - Cuff a nearby player (law only)
- `/escort` - Escort a restrained player (law only)
- `/mdt` - Open the Sheriffs Archives Terminal

## Keybinds

- Configurable keybind for law office prompts (default: J)
or /mdt

## Configuration

All configuration options are available in `config.lua`:
- Law office locations
- Keybinds
- Storage settings
- Alert settings
- Job access permissions

## Sheriffs Archives Terminal (MDT)

The MDT system provides law enforcement officers with access to a comprehensive database for managing criminal records, warrants, BOLOs, incident reports, and citations. For detailed information about the MDT system, see [MDT_README.md](MDT_README.md).

## Support

For issues or feature requests, please contact the resource maintainer or submit an issue on the GitHub repository.
