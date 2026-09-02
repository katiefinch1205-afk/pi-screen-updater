#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi to add double-clickable "Update Kiosk" and
# "Exit Kiosk" icons to the desktop, so neither needs a pasted command.

REPO_RAW="https://raw.githubusercontent.com/katiefinch1205-afk/pi-screen-updater/main"
WRAPPER_SCRIPT="$HOME/update-kiosk.sh"
EXIT_SCRIPT="$HOME/exit-kiosk.sh"
DESKTOP_DIR="$HOME/Desktop"
DESKTOP_FILE="$DESKTOP_DIR/update-kiosk.desktop"
EXIT_DESKTOP_FILE="$DESKTOP_DIR/exit-kiosk.desktop"

mkdir -p "$DESKTOP_DIR"

cat > "$WRAPPER_SCRIPT" <<EOF
#!/usr/bin/env bash
if ! curl -fsSL -o "\$HOME/update.sh" "$REPO_RAW/update.sh"; then
  echo "Failed to download update.sh"
  read -p "Press Enter to close..."
  exit 1
fi
chmod +x "\$HOME/update.sh"

if "\$HOME/update.sh"; then
  echo
  echo "Update applied. Rebooting in 5 seconds..."
  sleep 5
  sudo reboot
else
  echo
  echo "Update failed, see the errors above."
  read -p "Press Enter to close..."
fi
EOF
chmod +x "$WRAPPER_SCRIPT"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Update Kiosk
Comment=Pull latest kiosk config from GitHub and reapply
Exec=lxterminal -e "$WRAPPER_SCRIPT"
Icon=system-software-update
Terminal=false
EOF
chmod +x "$DESKTOP_FILE"

cat > "$EXIT_SCRIPT" <<'EOF'
#!/usr/bin/env bash
# Kill the watchdog first, otherwise it just relaunches chromium.
pkill -f pi-screen-kiosk-watchdog.sh
pkill chromium
EOF
chmod +x "$EXIT_SCRIPT"

cat > "$EXIT_DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Exit Kiosk
Comment=Stop chromium and the watchdog so the desktop stays free for maintenance
Exec=$EXIT_SCRIPT
Icon=application-exit
Terminal=false
EOF
chmod +x "$EXIT_DESKTOP_FILE"

echo "Desktop shortcuts installed:"
echo "  $DESKTOP_FILE (pulls and applies the latest kiosk config, then reboots)"
echo "  $EXIT_DESKTOP_FILE (stops chromium and the watchdog for maintenance)"
echo "If pcmanfm shows an 'untrusted launcher' prompt the first time, choose Trust/Execute."
