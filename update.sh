#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi to pull the latest kiosk-setup.sh from GitHub
# and reapply it. Safe to run any time; it just refreshes the autostart config.

REPO_RAW="https://raw.githubusercontent.com/katiefinch1205-afk/pi-screen-updater/main"

cd "$(dirname "$0")"

echo "Fetching latest kiosk-setup.sh..."
curl -fsSL -o kiosk-setup.sh "$REPO_RAW/kiosk-setup.sh"
chmod +x kiosk-setup.sh

echo "Applying..."
./kiosk-setup.sh

echo "Done. Reboot to apply: sudo reboot"
