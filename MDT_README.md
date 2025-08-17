# RSG Lawman MDT System

The Sheriffs Archives (SA) is an integrated law enforcement database system for the RSG Lawman resource. It provides officers with access to criminal records, warrants, Bounty Alerts, incident reports, and citation management directly from an in-game interface.

## Features

- **Person Search**: Search for citizens by name or citizen ID
- **Vehicle Search**: Search for vehicles by plate, model, or owner
- **Criminal Records**: View and manage criminal history
- **Warrants**: Issue, view, and manage arrest warrants
- **Bounty Alerts**: Create and track Be On the Lookout alerts for vehicles
- **Incident Reports**: File and view incident reports
- **Citations**: Issue and manage traffic/parking citations
- **Dashboard**: View recent incidents, active warrants, and Bounty Alerts at a glance

## Installation

1. Ensure you have the latest version of `rsg-lawman` installed
2. The MDT system is included by default in the latest version
3. Run the SQL schema in `mdt_schema.sql` to create the necessary database tables
4. Restart your server

## Usage

### Opening the MDT

1. **From Law Office Menu**: Access the MDT through the Law Office menu
2. **Keybind**: Press `M` (default) when on duty as a law enforcement officer

### Features Overview

#### Dashboard
The dashboard provides a quick overview of recent activity:
- Recent incidents from the past 7 days
- Active warrants
- Active Bounty Alerts
- Your recent reports

#### Persons Tab
Search for citizens and view their records:
- Search by name or citizen ID
- View personal information
- Check criminal history
- See issued citations
- View incident involvement
- Issue citations directly

#### Vehicles Tab
Search for vehicles and view related information:
- Search by plate, model, or owner
- View vehicle details
- Check for active Bounty Alerts
- View incident involvement
- Create Bounty Alerts directly

#### Reports Tab
Create incident reports:
- File new reports with title, description, and location

#### Warrants Tab
Manage arrest warrants:
- Issue new warrants with reason

#### Bounty Alerts Tab
Manage vehicle alerts:
- Access vehicle BOLO management through the Vehicles section

#### Citations Tab
Manage citations:
- Access citation management through the Persons section

## Commands

- `/mdt` - Open the Sheriffs Archives

## Keybinds

- `M` - Open MDT (when on duty as law enforcement)

## Database Schema

The MDT system uses several database tables to store information:
- `mdt_criminal_records` - Criminal charges and records
- `mdt_warrants` - Arrest warrants
- `mdt_Bounty Alerts` - Be On the Lookout alerts
- `mdt_incidents` - Incident reports
- `mdt_citations` - Traffic/parking citations
- `mdt_vehicles` - Vehicle records
- `mdt_reports` - General reports
- `mdt_logs` - System logs

## Configuration

The MDT system can be configured through the main `config.lua` file:
- `Config.MDTKeybind` - Key to open MDT (default: 'M')

## Requirements

- RSG Framework
- rsg-lawman resource
- oxmysql
- ox_lib

## Support

For issues or feature requests, please contact the resource maintainer or submit an issue on the GitHub repository.