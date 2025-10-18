# Linux Desktop Monitor

A tool to monitor and manage your Linux desktop from your Ubuntu Touch device via a lightweight HTTP server.

## Features

- 🔌 Connect to your Linux desktop via HTTP (no SSH required!)
- 📊 Real-time system metrics:
  - Hostname
  - Uptime
  - CPU usage
  - RAM usage
  - Temperature (if available)
- 📁 File browser to explore your desktop files
- ⬇️ Download files from desktop to your Ubuntu Touch device
- ⬆️ Upload files from Ubuntu Touch to your desktop
- ⚠️ Remote shutdown capability
- 🔒 Optional authentication token for security
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

Download the server script from the app's documentation or GitHub repository, then run it on your Linux desktop:

```bash
# Install required dependencies
pip3 install pillow pyautogui --break-system-packages

# Basic usage (no authentication)
python3 desktop_monitor_server.py

# With authentication token
python3 desktop_monitor_server.py --token mysecrettoken123

# Custom port
python3 desktop_monitor_server.py --port 9090

# Custom file root directory
python3 desktop_monitor_server.py --files-root ~/Documents
```

The server will display your IP address that you'll use in the app.

**Note**: The `--break-system-packages` flag is required on modern Linux distributions (Python 3.11+) and is safe for these user-space libraries.

**Optional: Install sensors for temperature monitoring**
```bash
sudo apt install lm-sensors
sudo sensors-detect
```

## Usage

1. **Install dependencies on your desktop**:
   ```bash
   pip3 install pillow pyautogui --break-system-packages
   ```

2. **Start the server on your desktop**: 
   ```bash
   python3 desktop_monitor_server.py
   ```

3. **Open the app on your Ubuntu Touch device**

4. **Enter your desktop's IP address and port** (default: 8080)

5. **Optional**: Enter authentication token if you started the server with `--token`

6. **Tap "Connect"** to view system metrics

7. **Browse Files**: Explore your desktop files, download to your device

8. **Upload Files**: Send files from your device to your desktop

9. **Shutdown**: Remotely shutdown your desktop when needed

## Current Status

**Version 1.0.0** ✅
- ✅ System monitoring (CPU, RAM, uptime, temperature)
- ✅ File browser with navigation
- ✅ Download files from desktop to device
- ✅ Upload files from device to desktop
- ✅ Remote shutdown capability
- ✅ Optional authentication token
- ✅ Connection settings persistence

**Future Features** (Planned)
- Multiple desktop profiles
- Background monitoring with notifications
- Scheduled tasks

## Development Notes

This app uses a **client-server architecture**:

- **Frontend**: QML + C++ (Qt5) for the Ubuntu Touch app
- **Backend**: Python HTTP server (`desktop_monitor_server.py`) running on your desktop
- **Communication**: HTTP/JSON API with base64 file encoding
- **Build system**: Clickable (handles all packaging automatically)
- **Security**: Works perfectly with Ubuntu Touch's AppArmor confinement model

## Troubleshooting

**"Connection failed"**
- Verify the server is running on your desktop
- Check firewall settings (port 8080 by default must be open)
- Ensure you entered the correct IP address
- If using authentication, verify the token matches

**"Network error"**
- Ensure both devices are on the same network
- Check if you can ping the desktop from your phone
- Try accessing `http://DESKTOP_IP:8080/metrics` from a browser

**"File operation error"**
- Files can only be uploaded from the app's folder due to Ubuntu Touch permissions
- Download a file to the app first, then you can upload it back
- Check the debug logs for detailed error messages

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
