#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi to add a double-clickable "Update Kiosk" icon
# to the desktop, so pulling the latest config doesn't need a pasted command.

REPO_RAW="https://raw.githubusercontent.com/katiefinch1205-afk/pi-screen-updater/main"
WRAPPER_SCRIPT="$HOME/update-kiosk.sh"
DESKTOP_DIR="$HOME/Desktop"
DESKTOP_FILE="$DESKTOP_DIR/update-kiosk.desktop"

mkdir -p "$DESKTOP_DIR"

cat > "$WRAPPER_SCRIPT" <<EOF
#!/usr/bin/env bash
set -e
curl -fsSL -o "\$HOME/update.sh" "$REPO_RAW/update.sh"
chmod +x "\$HOME/update.sh"
"\$HOME/update.sh"
echo
read -p "Press Enter to close..."
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

echo "Desktop shortcut installed at $DESKTOP_FILE"
echo "Double-click it to pull and apply the latest kiosk config."
echo "If pcmanfm shows an 'untrusted launcher' prompt the first time, choose Trust/Execute."
