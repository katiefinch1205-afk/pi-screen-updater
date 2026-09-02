#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi itself (Debian trixie, labwc/wlroots desktop,
# already set to auto-login). It configures the desktop session to launch
# Chromium full-screen against the warehouse display on every boot.
# Safe to re-run: replaces any previous kiosk block instead of duplicating it.

KIOSK_URL="http://10.10.2.194:3001/"
AUTOSTART_DIR="$HOME/.config/labwc"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

mkdir -p "$AUTOSTART_DIR"
touch "$AUTOSTART_FILE"

# Remove any existing chromium kiosk block before adding the current one.
sed -i '/^chromium \\/,/&$/d' "$AUTOSTART_FILE"

cat >> "$AUTOSTART_FILE" <<EOF

chromium \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --incognito \\
  --disable-session-crashed-bubble \\
  --disable-restore-session-state \\
  --overscroll-history-navigation=0 \\
  --check-for-update-interval=31536000 \\
  --password-store=basic \\
  --ozone-platform=wayland \\
  $KIOSK_URL &
EOF

chmod +x "$AUTOSTART_FILE"

echo "Kiosk config applied to $AUTOSTART_FILE"
echo "Reboot the Pi to apply: sudo reboot"
