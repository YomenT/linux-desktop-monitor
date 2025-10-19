# Linux Desktop Monitor

A tool to monitor and manage your Linux desktop from your Ubuntu Touch device via a lightweight HTTP server.

## Features

- Connect to your Linux desktop via HTTP (no SSH required!)
- Real-time system metrics:
  - Hostname
  - Uptime
  - CPU usage
  - RAM usage
  - Temperature (if available)
- File browser to explore your desktop files
- Download files from desktop to your Ubuntu Touch device
- Upload files from Ubuntu Touch to your desktop
- Remote shutdown capability
- Optional authentication token for security
- Refresh metrics on demand
- Saves connection settings

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

Download the server script from the app's documentation or GitHub repository, then run it on your Linux desktop.

#### Option 1: Using Virtual Environment (Recommended)

```bash
# Create a virtual environment
python3 -m venv monitor-env

# Activate it
source monitor-env/bin/activate

# Install dependencies
pip install pillow pyautogui

# Run the server
python3 desktop_monitor_server.py

# When done, deactivate
deactivate
```

#### Option 2: System-wide Install

```bash
# Install dependencies system-wide
# Note: Use this if you understand the implications or if your system allows it
pip3 install pillow pyautogui --break-system-packages
```

**Note on `--break-system-packages`**: This flag is needed on modern Linux distributions (Python 3.11+) that use externally-managed Python environments. While Pillow and pyautogui are safe libraries, using a virtual environment (Option 1) is the recommended best practice to avoid any potential conflicts with system packages.

#### Server Usage

```bash
# Basic usage (no authentication)
python3 desktop_monitor_server.py

# With authentication token for security
python3 desktop_monitor_server.py --token mysecrettoken123

# Custom port
python3 desktop_monitor_server.py --port 9090

# Custom file root directory
python3 desktop_monitor_server.py --files-root ~/Documents
```

The server will display your IP address that you'll use in the app.

#### Optional: Temperature Monitoring

For CPU/system temperature monitoring, install lm-sensors:

```bash
sudo apt install lm-sensors
sudo sensors-detect
```

## Usage

1. **Complete the Desktop Setup** (see above)

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

9. **Remote Desktop Control**: 
   - View your desktop screen in real-time
   - Control with touch (click, right-click, scroll)
   - Pinch to zoom for precise control
   - Virtual keyboard for text input
   - Special keys: Enter, Tab, Esc, Backspace, Delete

10. **Shutdown**: Remotely shutdown your desktop when needed