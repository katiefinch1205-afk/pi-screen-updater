#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi itself (Debian trixie, labwc/wlroots desktop,
# already set to auto-login). It configures the desktop session to launch
# Chromium full-screen against the warehouse display on every boot.

KIOSK_URL="http://10.10.2.194:3001/"
AUTOSTART_DIR="$HOME/.config/labwc"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

mkdir -p "$AUTOSTART_DIR"
touch "$AUTOSTART_FILE"

if ! grep -q "$KIOSK_URL" "$AUTOSTART_FILE" 2>/dev/null; then
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
  echo "Added kiosk launch to $AUTOSTART_FILE"
else
  echo "Kiosk launch already present in $AUTOSTART_FILE, skipping"
fi

chmod +x "$AUTOSTART_FILE"

echo "Done. Reboot the Pi to test: sudo reboot"
