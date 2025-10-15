# Installing Dependencies on Ubuntu Touch Device

Your app requires `python3` and `sshpass` to be installed on your Ubuntu Touch device to work properly.

## Install via SSH to your device:

1. **Enable SSH on your Ubuntu Touch device** (via System Settings → Developer Mode)

2. **Connect to your device** from your PC:
```bash
ssh phablet@<your-device-ip>
```

3. **Make the filesystem writable**:
```bash
sudo mount -o remount,rw /
```

4. **Install required packages**:
```bash
sudo apt update
sudo apt install -y python3 sshpass
```

5. **Make filesystem read-only again** (recommended):
```bash
sudo mount -o remount,ro /
```

## Verify Installation:

```bash
which python3
which sshpass
```

Both commands should return a path.

## Note:

The dependencies are already installed on most Ubuntu Touch devices. If the app doesn't work, follow the steps above to ensure they're present.
