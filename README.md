# Linux Desktop Monitor

A tool to monitor and manage your Linux desktop from your Ubuntu Touch device via SSH.

## Features

- 🔌 SSH connection to your Linux desktop
- 📊 Real-time system metrics:
  - Hostname
  - Uptime
  - CPU usage
  - RAM usage
  - Temperature (if available)
- 🔄 Refresh metrics on demand
- 💾 Saves connection settings

## Building and Testing

### Prerequisites

- Clickable installed on your development machine
- Ubuntu Touch device or emulator

### Build and Install

```bash
cd linux-desktop-monitor
clickable
```

This will build the app and install it on your device/emulator.

### Desktop Setup

Your Linux desktop needs to have SSH server running:

```bash
# Install SSH server (if not already installed)
sudo apt install openssh-server

# Start SSH service
sudo systemctl start sshd
sudo systemctl enable sshd

# Optional: Install sensors for temperature monitoring
sudo apt install lm-sensors
sudo sensors-detect
```

## Usage

1. Open the app on your Ubuntu Touch device
2. Enter your desktop's:
   - Hostname or IP address
   - SSH username
   - SSH password
   - Port (default: 22)
3. Tap "Connect"
4. View your system metrics
5. Use "Refresh" to update the information

## Current Status

**Phase 1: Basic Monitoring** ✅
- UI for SSH connection
- Python script for fetching metrics
- Display system information

**Phase 2: Advanced Features** (Planned)
- Remote shutdown capability
- File transfer between devices
- Multiple desktop profiles
- Background monitoring with notifications

## Development Notes

This is a **QML-only app** with a Python helper script for SSH operations. The architecture:

- **Frontend**: QML (similar to web development - HTML/CSS/JS)
- **Backend**: Python script using `sshpass` for SSH
- **Build system**: Clickable (handles all packaging automatically)

## Troubleshooting

**"Connection failed"**
- Verify SSH is running on your desktop
- Check firewall settings
- Ensure credentials are correct
- Try connecting from terminal: `ssh username@hostname`

**"Network error"**
- Ensure both devices are on the same network
- Check if you can ping the desktop from your phone

## License

Copyright (C) 2025  Yomen Tohmaz

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranties of MERCHANTABILITY, SATISFACTORY
QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
