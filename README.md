# ASL3 HDMI Desktop Choices

**Add an HDMI desktop to your AllStarLink system, with browser access to your dashboard and a terminal.**

This repository contains two HDMI desktop scripts:

- A **LightDM/Openbox desktop installer** with a bottom taskbar.
- A **coloured dashboard selector add-on** for an existing `asl3-hdmi.service` installation.

Created by **M0FXBANDREAS / HamTech M0FXB**.

## Choose the correct script

| Script | Purpose | Required starting point |
| --- | --- | --- |
| `asl3-hdmi-install (1).sh` | Installs an automatically logged-in Openbox desktop with Chromium, a taskbar and terminal launcher. | An AllStarLink appliance image and a normal user account with sudo access. |
| `asl3-hdmi-desktop (1).sh` | Adds large coloured dashboard buttons, desktop icons and a bottom application panel. | An existing HDMI service with `/usr/local/bin/asl3-hdmi-session` and `/etc/default/asl3-hdmi`. |

> **Important:** these scripts are not a two-step installation sequence. The LightDM installer does not create the service or configuration files required by the coloured-button add-on. Running the add-on immediately after the LightDM installer will therefore fail its prerequisite check.

## Requirements

- An AllStarLink appliance installation.
- A connected HDMI monitor and suitable cable or adapter.
- SSH access through a normal user account with sudo permissions.
- Internet access for package downloads.
- A working dashboard or system web interface.

The LightDM installer is described in its source as targeting **Debian 13 / Raspberry Pi**. Its compatibility check verifies the AllStarLink appliance identifier; it does not separately verify the Debian version or Raspberry Pi hardware.

## Option 1: Install the HDMI desktop

This option creates a lightweight desktop using:

- **LightDM** for automatic desktop login.
- **Openbox** as the window manager.
- **Tint2** for the bottom taskbar.
- **Chromium** for web access.
- **Xterm** for terminal access.

Chromium opens automatically at:

```text
http://localhost:9090/
```

The taskbar includes dashboard and terminal launchers, running application buttons and a clock.

### 1. Connect your monitor

Connect and turn on the HDMI display.

### 2. Log in through SSH

Use your normal AllStarLink user account. Run the installation with `sudo` from that account.

### 3. Download the installer

```bash
wget -O /tmp/asl3-hdmi-install.sh 'https://raw.githubusercontent.com/M0FXBANDREAS/HDMI-ASL3-DESKTOP-CHOICES/main/asl3-hdmi-install%20%281%29.sh'
```

### 4. Run the installer

```bash
sudo bash /tmp/asl3-hdmi-install.sh
```

The installer downloads packages, writes the desktop configuration, enables LightDM and selects graphical startup.

### 5. Reboot after successful installation

```bash
sudo reboot
```

The HDMI desktop should log in automatically using the account that ran the installer through sudo.

> Desktop automatic login does not bypass the ASL3 web login. Authentication to the web interface is still required.

If installation reports a failure, resolve it before rebooting.

## Option 2: Add coloured dashboard buttons

This add-on is intended for an existing service-based HDMI setup.

Before installing, confirm these files exist:

```bash
ls -l /usr/local/bin/asl3-hdmi-session /etc/default/asl3-hdmi
```

The existing setup must also provide `asl3-hdmi.service` and define the `KIOSK_USER` and `KIOSK_HOME` values in `/etc/default/asl3-hdmi`.

### Download and install

```bash
wget -O /tmp/asl3-hdmi-desktop.sh 'https://raw.githubusercontent.com/M0FXBANDREAS/HDMI-ASL3-DESKTOP-CHOICES/main/asl3-hdmi-desktop%20%281%29.sh'
```

```bash
sudo bash /tmp/asl3-hdmi-desktop.sh
```

The add-on installs a Python/Tkinter selector, PCManFM, LXPanel and LXTerminal. It changes Chromium from kiosk mode to a maximized window and restarts the existing HDMI service.

### Dashboard buttons

| Button | Default action |
| --- | --- |
| **Connections** | Opens `http://192.168.0.100/allmon3/`. |
| **Main Dashboard** | Opens `http://192.168.0.100/`. |
| **System :9090** | Opens `http://192.168.0.100:9090/`. |
| **Desktop** | Minimizes Chromium to expose the desktop. |

Click a dashboard button to restore the browser and open the selected page.

The desktop includes file manager and terminal shortcuts, plus a bottom application menu, taskbar and clock.

### Set your node’s address

The add-on uses the fixed address **192.168.0.100**. Change it if your node uses a different address.

After installation, edit:

```bash
sudo nano /usr/local/bin/asl3-hdmi-buttons
```

Update the URLs in the `PAGES` list, save the file and restart the service:

```bash
sudo systemctl restart asl3-hdmi.service
```

The buttons open existing web services. They do not install Allmon3 or create the pages they point to.

## Troubleshooting

### No HDMI picture

Check the monitor power, selected input and HDMI cable.

Then use the diagnostics for your chosen installation.

**LightDM desktop:**

```bash
sudo systemctl status lightdm --no-pager
sudo journalctl -u lightdm -n 60 --no-pager
```

**Service-based coloured-button setup:**

```bash
sudo systemctl status asl3-hdmi.service --no-pager
sudo journalctl -u asl3-hdmi.service -n 60 --no-pager
```

### The add-on says “Install the ASL3 HDMI service first”

The required service-based installation is missing. The LightDM installer in this repository does not supply that setup.

### A dashboard page does not load

Check that the address is correct and the relevant web service is running.

- The LightDM desktop opens `http://localhost:9090/`.
- The coloured-button add-on uses `192.168.0.100` until you edit its URLs.

### Buttons do not respond immediately

Allow Chromium to finish starting, then try again. The selector searches for a Chromium window before switching pages.

### The installer rejects the user account

Run it from your normal AllStarLink account using `sudo bash`. The LightDM installer rejects root as the desktop login user.

## Backups

### LightDM installer

Existing configuration files are backed up beside their originals with names ending in:

```text
.backup-YYYYMMDD-HHMMSS
```

These cover the Openbox autostart file, Tint2 configuration, dashboard and terminal launchers, and the installer’s LightDM configuration file.

### Coloured-button add-on

Previous session and selector files, when present, are backed up under:

```text
/var/backups/asl3-hdmi-desktop.XXXXXXXX/
```

An existing panel directory is also copied into that backup.

The add-on prints the actual backup location when installation completes.

These backups are configuration backups, not complete system backups. Neither script provides a full automatic uninstall or rollback.

## Disable automatic HDMI startup

### LightDM desktop

To return to console startup:

```bash
sudo systemctl disable lightdm
sudo systemctl set-default multi-user.target
```

These commands affect future startup. To stop the current desktop immediately:

```bash
sudo systemctl stop lightdm
```

### Service-based setup

```bash
sudo systemctl disable --now asl3-hdmi.service
```

Disabling startup does not remove installed packages or configuration files.

## Project files

| File | Description |
| --- | --- |
| `asl3-hdmi-install (1).sh` | LightDM/Openbox desktop installer. |
| `asl3-hdmi-desktop (1).sh` | Coloured-button and desktop add-on for an existing HDMI service. |
| `HDMI-ALLSTAR.zip` | Additional ZIP archive supplied in the repository. |

## Credits

Many thanks to the **AllStarLink team** and the developers of the desktop tools used by this project.

[HDMI ASL3 Desktop Choices on GitHub](https://github.com/M0FXBANDREAS/HDMI-ASL3-DESKTOP-CHOICES)

**73 — HamTech M0FXB**

wget -O /tmp/asl3-hdmi-desktop.sh 'https://raw.githubusercontent.com/M0FXBANDREAS/HDMI-ASL3-DESKTOP-CHOICES/main/asl3-hdmi-desktop%20%281%29.sh' && sudo bash /tmp/asl3-hdmi-desktop.sh

wget -O /tmp/asl3-hdmi-install.sh 'https://raw.githubusercontent.com/M0FXBANDREAS/HDMI-ASL3-DESKTOP-CHOICES/main/asl3-hdmi-install.sh' && sudo bash /tmp/asl3-hdmi-install.sh
