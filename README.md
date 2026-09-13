# Battery Monitor

A lightweight macOS battery monitoring utility that warns the user when the battery level becomes low and helps prevent unexpected shutdowns caused by battery depletion.

## Overview

Battery Monitor runs as a background LaunchAgent and periodically checks the current battery level.

The goal of this project is to protect unsaved work on older Mac hardware where sudden power loss may occur due to battery degradation, aging batteries, or unexpected shutdowns.

The monitor provides:

- Audible alerts
- Native macOS dialog warnings
- Configurable battery thresholds
- Optional emergency shutdown protection

## Features

### Battery Monitoring

The monitor checks the battery status every 3 minutes using macOS system tools.

Default thresholds:

| Battery Level | Action |
|---|---|
| 30% | Warning dialog asking the user to save work and connect the charger |
| 25% | Low battery warning |
| 20% | Critical battery warning with optional shutdown |

### Critical Battery Protection

When the battery reaches the critical level:

- A warning dialog appears.
- The user can choose:
  - OK: schedule shutdown in 5 minutes.
  - Cancel: continue running.

The shutdown command is only executed after user confirmation.

If the charger is connected before shutdown occurs, the pending shutdown is cancelled automatically.

## Alerts

Each warning includes:

- macOS native dialog
- System alert sound

The dialogs are displayed inside the active graphical user session.

## Installation

Make the installer executable:

    chmod +x install-batterymonitor.sh

Install:

    ./install-batterymonitor.sh --install

The installer creates:

    ~/bin/
    ├── battery-monitor.sh
    └── install-batterymonitor.sh

and:

    ~/Library/LaunchAgents/
    └── com.batterymonitor.plist

## Usage

### Test alerts

    ~/bin/install-batterymonitor.sh --test

### Check service status

    launchctl list | grep batterymonitor

Detailed information:

    launchctl print gui/$(id -u)/com.batterymonitor

## Logs

Runtime log:

    /tmp/batterymonitor.log

LaunchAgent output:

    /tmp/batterymonitor.out
    /tmp/batterymonitor.err

## Uninstall

Remove Battery Monitor:

    ~/bin/install-batterymonitor.sh --uninstall

## Project Structure

    Battery Monitor

    install-batterymonitor.sh

    Installed files:

    ~/bin/
    ├── battery-monitor.sh
    └── install-batterymonitor.sh

    ~/Library/LaunchAgents/
    └── com.batterymonitor.plist

## Requirements

- macOS
- Bash
- pmset
- osascript
- LaunchAgents support

No additional dependencies are required.

## Design Notes

Battery Monitor uses a LaunchAgent instead of a daemon because:

- Dialogs require access to the user graphical session.
- It runs only for the logged-in user.
- It has minimal CPU and memory usage.

The monitor wakes every 180 seconds, checks the battery state, performs any required action, and exits.

## License

Free to use and modify.