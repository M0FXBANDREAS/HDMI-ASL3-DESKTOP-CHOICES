#!/usr/bin/env bash
# ASL3 HDMI dashboard installer — Debian 13 / Raspberry Pi.
set -Eeuo pipefail
trap 'echo "Installation failed at line $LINENO. Do not reboot until resolved." >&2' ERR
if (( EUID != 0 )); then
    exec sudo bash "$0" "$@"
fi
desktop_user=${SUDO_USER:-allstar3}
if [[ "$desktop_user" == root ]] || ! id "$desktop_user" >/dev/null 2>&1; then
    echo "Run from your normal ASL3 user account using sudo bash." >&2
    exit 1
fi
if ! grep -q '^VARIANT_ID="\?AllStarLink' /etc/os-release; then
    echo "This installer requires an AllStarLink appliance image." >&2
    exit 1
fi
desktop_home=$(getent passwd "$desktop_user" | cut -d: -f6)
desktop_group=$(id -gn "$desktop_user")
stamp=$(date +%Y%m%d-%H%M%S)
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xserver-xorg lightdm lightdm-gtk-greeter openbox tint2 chromium xterm dbus-x11 x11-xserver-utils fonts-dejavu
install -d -o "$desktop_user" -g "$desktop_group" "$desktop_home/.config/openbox" "$desktop_home/.config/tint2" "$desktop_home/.local/share/applications"
mkdir -p /etc/lightdm/lightdm.conf.d
for file in "$desktop_home/.config/openbox/autostart" "$desktop_home/.config/tint2/tint2rc" "$desktop_home/.local/share/applications/asl3-dashboard.desktop" "$desktop_home/.local/share/applications/asl3-terminal.desktop" /etc/lightdm/lightdm.conf.d/90-asl3-hdmi.conf; do
    if [[ -f "$file" ]]; then cp -a "$file" "$file.backup-$stamp"; fi
done
cat > "$desktop_home/.local/share/applications/asl3-dashboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=ASL3 Dashboard
Exec=chromium --start-maximized --no-first-run http://localhost:9090/
Icon=web-browser
Terminal=false
EOF
cat > "$desktop_home/.local/share/applications/asl3-terminal.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Exec=xterm -fa Monospace -fs 14
Icon=utilities-terminal
Terminal=false
EOF
cat > "$desktop_home/.config/tint2/tint2rc" <<EOF
rounded = 0
border_width = 0
background_color = #202830 100
panel_items = LTC
panel_size = 100% 52
panel_position = bottom center horizontal
panel_padding = 8 4 8
panel_layer = top
strut_policy = follow_size
autohide = 0
launcher_padding = 8 4 12
launcher_icon_size = 36
launcher_item_app = $desktop_home/.local/share/applications/asl3-dashboard.desktop
launcher_item_app = $desktop_home/.local/share/applications/asl3-terminal.desktop
launcher_tooltip = 1
taskbar_mode = single_desktop
task_text = 1
task_icon = 1
task_maximum_size = 220 40
task_font = Sans 12
task_font_color = #ffffff 100
time1_format = %H:%M
time1_font = Sans 14
clock_font_color = #ffffff 100
clock_padding = 10 0
mouse_left = toggle_iconify
mouse_right = close
EOF
cat > "$desktop_home/.config/openbox/autostart" <<'EOF'
xset s off
xset -dpms
xset s noblank
tint2 &
(sleep 5; chromium --start-maximized --no-first-run http://localhost:9090/) &
EOF
cat > /etc/lightdm/lightdm.conf.d/90-asl3-hdmi.conf <<EOF
[Seat:*]
autologin-user=$desktop_user
autologin-user-timeout=0
user-session=openbox
autologin-session=openbox
greeter-session=lightdm-gtk-greeter
EOF
chown "$desktop_user:$desktop_group" "$desktop_home/.config/openbox/autostart" "$desktop_home/.config/tint2/tint2rc" "$desktop_home/.local/share/applications/asl3-dashboard.desktop" "$desktop_home/.local/share/applications/asl3-terminal.desktop"
systemctl enable lightdm
systemctl set-default graphical.target
echo "HDMI setup complete. Desktop auto-login enabled for $desktop_user."
echo "ASL3 web login is still required. Reboot when ready: sudo reboot"
