#!/usr/bin/env bash
set -euo pipefail

# Run this on the Raspberry Pi itself (Debian trixie, labwc/wlroots desktop,
# pcmanfm managing the desktop/wallpaper, already set to auto-login).
# Safe to re-run: replaces its own managed block instead of duplicating it.

KIOSK_URL="http://10.10.2.194:3001/"
AUTOSTART_DIR="$HOME/.config/labwc"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"
INFO_SCRIPT="$HOME/.local/bin/pi-screen-desktop-info.sh"
WATCHDOG_SCRIPT="$HOME/.local/bin/pi-screen-kiosk-watchdog.sh"
START_MARKER="# >>> pi-screen-updater managed block >>>"
END_MARKER="# <<< pi-screen-updater managed block <<<"

if ! command -v convert >/dev/null 2>&1; then
  echo "Installing imagemagick for the desktop info wallpaper..."
  sudo apt-get update -y
  sudo apt-get install -y imagemagick
fi

mkdir -p "$AUTOSTART_DIR" "$(dirname "$INFO_SCRIPT")"
touch "$AUTOSTART_FILE"

# Remove a pre-marker chromium block left by older versions of this script.
sed -i '/^chromium \\/,/&$/d' "$AUTOSTART_FILE"
# Remove any existing managed block from a previous run of this script.
sed -i "/$START_MARKER/,/$END_MARKER/d" "$AUTOSTART_FILE"

cat > "$INFO_SCRIPT" <<'INFO_EOF'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v convert >/dev/null 2>&1; then
  echo "ImageMagick not found, run: sudo apt install -y imagemagick" >&2
  exit 1
fi

OUT_DIR="$HOME/.cache/pi-screen-updater"
OUT_IMG="$OUT_DIR/desktop-info.png"
mkdir -p "$OUT_DIR"

HOSTNAME_STR="$(hostname)"
IP_STR="$(hostname -I | awk '{print $1}')"

convert -size 1920x1080 xc:'#1a1a1a' \
  -gravity SouthEast -pointsize 28 -fill white \
  -annotate +40+40 "${HOSTNAME_STR}
${IP_STR}" \
  "$OUT_IMG"

pcmanfm --set-wallpaper="$OUT_IMG" --wallpaper-mode=stretch
INFO_EOF
chmod +x "$INFO_SCRIPT"

cat > "$WATCHDOG_SCRIPT" <<'WATCHDOG_EOF'
#!/usr/bin/env bash
set -uo pipefail

# Launches chromium in kiosk mode and keeps it pointed at a working page.
# If the target URL stops responding, kills chromium, waits, and relaunches.

KIOSK_URL="__KIOSK_URL__"
CHECK_INTERVAL=10   # seconds between page checks while chromium is running
RETRY_DELAY=20      # seconds to wait after a failed page before relaunching

CHROME_ARGS=(
  --kiosk
  --noerrdialogs
  --disable-infobars
  --incognito
  --disable-session-crashed-bubble
  --disable-restore-session-state
  --overscroll-history-navigation=0
  --check-for-update-interval=31536000
  --password-store=basic
  --ozone-platform=wayland
)

is_page_up() {
  curl -fsS -o /dev/null --max-time 5 "$KIOSK_URL"
}

while true; do
  chromium "${CHROME_ARGS[@]}" "$KIOSK_URL" &
  CHROME_PID=$!

  # Give the page a few seconds to attempt loading before the first check.
  sleep 5

  while kill -0 "$CHROME_PID" 2>/dev/null; do
    if ! is_page_up; then
      echo "$(date): page unreachable, restarting chromium"
      kill "$CHROME_PID" 2>/dev/null || true
      wait "$CHROME_PID" 2>/dev/null || true
      break
    fi
    sleep "$CHECK_INTERVAL"
  done

  sleep "$RETRY_DELAY"
done
WATCHDOG_EOF
sed -i "s|__KIOSK_URL__|$KIOSK_URL|" "$WATCHDOG_SCRIPT"
chmod +x "$WATCHDOG_SCRIPT"

cat >> "$AUTOSTART_FILE" <<EOF

$START_MARKER
$INFO_SCRIPT &
$WATCHDOG_SCRIPT &
$END_MARKER
EOF

chmod +x "$AUTOSTART_FILE"

echo "Kiosk config applied to $AUTOSTART_FILE"
echo "Desktop info script installed at $INFO_SCRIPT (runs on every login, sets wallpaper to hostname + IP)"
echo "Watchdog installed at $WATCHDOG_SCRIPT (restarts chromium if the page becomes unreachable)"
echo "Reboot the Pi to apply: sudo reboot"
