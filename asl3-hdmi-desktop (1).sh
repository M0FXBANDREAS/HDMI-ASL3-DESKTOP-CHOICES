#!/bin/bash
# ASL3 HDMI: larger coloured dashboard buttons and lightweight desktop.
set -Eeuo pipefail
[[ $EUID == 0 ]] || { echo 'Run: sudo bash asl3-hdmi-desktop.sh'; exit 1; }
[[ -f /usr/local/bin/asl3-hdmi-session && -f /etc/default/asl3-hdmi ]] || { echo 'Install the ASL3 HDMI service first.'; exit 1; }
. /etc/default/asl3-hdmi
getent passwd "$KIOSK_USER" >/dev/null
apt-get update
apt-get install -y --no-install-recommends python3-tk xdotool x11-utils pcmanfm lxpanel lxterminal lxde-icon-theme desktop-file-utils
backup=$(mktemp -d /var/backups/asl3-hdmi-desktop.XXXXXXXX)
for f in /usr/local/bin/asl3-hdmi-session /usr/local/bin/asl3-hdmi-buttons; do
  [[ ! -e $f ]] || cp -a "$f" "$backup/"
done
panel_dir="$KIOSK_HOME/.config/lxpanel/asl3-hdmi/panels"
if [[ -d $panel_dir ]]; then cp -a "$panel_dir" "$backup/previous-panels"; fi
install -d -o "$KIOSK_USER" -g "$(id -gn "$KIOSK_USER")" "$panel_dir"
cat >"$panel_dir/panel" <<'PANEL'
Global {
    edge=bottom
    align=center
    margin=0
    widthtype=percent
    width=100
    height=36
    transparent=0
    setdocktype=1
    setpartialstrut=1
    iconsize=28
}
Plugin {
    type=menu
    Config {
        image=lxde-icon
        system {
        }
    }
}
Plugin {
    type=launchbar
    Config {
        Button {
            id=pcmanfm.desktop
        }
        Button {
            id=lxterminal.desktop
        }
    }
}
Plugin {
    type=taskbar
    expand=1
    Config {
        tooltips=1
        IconsOnly=0
        ShowAllDesks=0
    }
}
Plugin {
    type=dclock
    Config {
        ClockFmt=%H:%M
        TooltipFmt=%A %d %B
    }
}
PANEL
chown "$KIOSK_USER:$(id -gn "$KIOSK_USER")" "$panel_dir/panel"
runuser -u "$KIOSK_USER" -- mkdir -p "$KIOSK_HOME/Desktop"
# Provide obvious desktop shortcuts as well as the bottom application menu.
for launcher in pcmanfm lxterminal; do
 if [[ -f /usr/share/applications/$launcher.desktop && ! -e $KIOSK_HOME/Desktop/$launcher.desktop ]]; then
  install -o "$KIOSK_USER" -g "$(id -gn "$KIOSK_USER")" -m 755 "/usr/share/applications/$launcher.desktop" "$KIOSK_HOME/Desktop/$launcher.desktop"
 fi
done
systemctl stop asl3-hdmi.service
cat >/usr/local/bin/asl3-hdmi-buttons <<'PY'
#!/usr/bin/python3
import subprocess
import tkinter as tk

PAGES = [
    ('Connections', 'http://192.168.0.100/allmon3/'),
    ('Main Dashboard', 'http://192.168.0.100/'),
    ('System :9090', 'http://192.168.0.100:9090/'),
    ('Desktop', None),
]
subprocess.Popen(['pcmanfm', '--desktop', '--profile', 'asl3-hdmi'])
subprocess.Popen(['lxpanel', '--profile', 'asl3-hdmi'])
root = tk.Tk()
root.title('ASL3 Dashboard Selector')
root.configure(bg='#10293d')
root.attributes('-type', 'dock')
root.attributes('-topmost', True)
height = 100
width = root.winfo_screenwidth()
root.geometry(f'{width}x{height}+0+0')
root.resizable(False, False)
status = tk.StringVar(value='Choose a dashboard')
buttons = []

def switch(index):
    # Search only mapped browser windows. Never send keys to the terminal.
    try:
        result = subprocess.run(
            ['xdotool', 'search', '--class', 'chromium'],
            capture_output=True, text=True, timeout=3, check=True)
        windows = result.stdout.split()
        if not windows:
            raise RuntimeError('Browser is not ready')
        window = windows[0]
        if index == 3:
            subprocess.run(['xdotool', 'windowminimize', window], timeout=3, check=True)
            status.set('Desktop')
            return
        subprocess.run(['xdotool', 'windowactivate', '--sync', window],
                       timeout=3, check=True)
        subprocess.run(['xdotool', 'key', '--clearmodifiers', 'ctrl+l'],
                       timeout=3, check=True)
        subprocess.run(['xdotool', 'type', '--clearmodifiers', '--delay', '1', PAGES[index][1]],
                       timeout=3, check=True)
        subprocess.run(['xdotool', 'key', '--clearmodifiers', 'Return'],
                       timeout=3, check=True)
        for n, button in enumerate(buttons):
            button.configure(relief='sunken' if n == index else 'raised')
        status.set(PAGES[index][0])
    except Exception:
        status.set('Browser starting - try again')

COLOURS = ['#126B36', '#185B9D', '#923A13', '#713F98']
LABELS = ['Connections', 'Main\nDashboard', 'System\n:9090', 'Desktop']
for i, (label, _) in enumerate(PAGES):
    button = tk.Button(root, text=LABELS[i], font=('DejaVu Sans', 18 if width >= 1000 else 13, 'bold'),
                       fg='white', bg=COLOURS[i], activebackground=COLOURS[i],
                       activeforeground='white', relief='raised', borderwidth=3, padx=8,
                       command=lambda n=i: switch(n))
    button.pack(side='left', fill='both', expand=True, padx=6, pady=8)
    buttons.append(button)

# Reserve the top strip so Openbox maximizes Chromium below the buttons.
def reserve():
    root.update_idletasks()
    window = root.wm_frame()
    subprocess.run(['xprop', '-id', window, '-f', '_NET_WM_STRUT', '32c',
                    '-set', '_NET_WM_STRUT', f'0, 0, {height}, 0'], check=True)
    values = f'0, 0, {height}, 0, 0, 0, 0, 0, 0, {width-1}, 0, 0'
    subprocess.run(['xprop', '-id', window, '-f', '_NET_WM_STRUT_PARTIAL', '32c',
                    '-set', '_NET_WM_STRUT_PARTIAL', values], check=True)
root.after(300, reserve)
root.mainloop()
PY
chmod 755 /usr/local/bin/asl3-hdmi-buttons
python3 - <<'PY'
from pathlib import Path
p=Path('/usr/local/bin/asl3-hdmi-session')
s=p.read_text().replace('--kiosk', '--start-maximized')
if '--disable-gpu' not in s:
    s=s.replace('--start-maximized', '--start-maximized --disable-gpu')
old='runuser -u "$KIOSK_USER" -- env HOME="$KIOSK_HOME" DISPLAY="$DISPLAY" XAUTHORITY=/dev/null /usr/local/bin/asl3-hdmi-buttons &'
new='runuser -u "$KIOSK_USER" -- env HOME="$KIOSK_HOME" DISPLAY="$DISPLAY" XAUTHORITY=/dev/null dbus-run-session -- /usr/local/bin/asl3-hdmi-buttons &'
if old in s:
    s=s.replace(old,new)
elif new not in s:
    marker='exec runuser -u "$KIOSK_USER" -- env'
    if marker not in s:
        raise SystemExit('Unknown session format. Ask for help; backup is in /var/backups.')
    s=s.replace(marker,new+'\n'+marker,1)
p.write_text(s)
PY
bash -n /usr/local/bin/asl3-hdmi-session
systemctl start asl3-hdmi.service
printf '\nDesktop and larger coloured buttons installed. Backup: %s\n' "$backup"
echo 'Desktop minimises Chromium. Use Files / Terminal or the bottom application menu.'
echo 'Click any dashboard button to restore the browser.'
echo 'Logs: sudo journalctl -u asl3-hdmi.service -n 60 --no-pager'
