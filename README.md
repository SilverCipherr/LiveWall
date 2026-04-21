# LiveWall
# Live Wallpaper System for Hyprland

A lightweight, efficient live wallpaper engine for Hyprland using `mpvpaper`. It automatically pauses the live wallpaper when a window is active to save resources, and includes a `rofi` script to easily select your wallpaper on the fly.

##  Features
- **Auto-pause functionality:** Pauses the live wallpaper when a window is active (saving CPU/GPU).
- **Rofi integration:** Easy graphical UI to switch wallpapers.
- **Support for multiple formats:** Uses MPV underneath, supporting `.mp4`, `.mkv`, and `.webm`.
- **Persistent State:** Updates the engine script automatically so that the selected wallpaper persists across reboots.

##  Prerequisites

To run this setup on an Arch Linux machine, you will need the following packages installed:

```bash
# Install required packages (Assuming yay is installed)
yay -S mpvpaper hyprland jq socat rofi
```

### Dependency Breakdown:
- `mpvpaper` : The core video wallpaper engine.
- `hyprland` : The compositor (provides `hyprctl` to check window state).
- `jq` : Command-line JSON processor to parse `hyprctl` data.
- `socat` : Core utility for data transfer via IPC to control pause/play states in MPV.
- `rofi` : Application launcher used here as a simple wallpaper selection menu.

##  Installation & Setup

### 1. Preparation
Create a directory to store your live wallpapers, and another for your scripts if you haven't already.

```bash
mkdir -p ~/Videos/LiveWallpapers
mkdir -p ~/.local/bin
```
*Note: Make sure to place some video files (`.mp4`, `.mkv`, or `.webm`) in the `~/Videos/LiveWallpapers` folder.*

### 2. The Engine Script (`wallpaper-engine.sh`)
Create the file `~/.local/bin/wallpaper-engine.sh`. This is the core daemon handling playback and pause events.

```bash
#!/bin/bash

SOCK="/tmp/mpvpaper-socket"
VIDEO="Your video path (Full. Need first time only)"

pkill mpvpaper 2>/dev/null

mpvpaper -f -o "input-ipc-server=$SOCK --no-audio --loop" ALL "$VIDEO" &

sleep 2

STATE="play"

while true; do
    active=$(hyprctl activewindow -j | jq -r '.class')

    if [ "$active" = "null" ] || [ -z "$active" ]; then
        if [ "$STATE" != "play" ]; then
            echo '{ "command": ["set_property", "pause", false] }' | socat - $SOCK >/dev/null 2>&1
            STATE="play"
        fi
    else
        if [ "$STATE" != "pause" ]; then
            echo '{ "command": ["set_property", "pause", true] }' | socat - $SOCK >/dev/null 2>&1
            STATE="pause"
        fi
    fi

    sleep 0.5
done
```

### 3. The Picker Script (`wallpaper-picker.sh`)
Create the file `~/.local/bin/wallpaper-picker.sh`. This provides the graphical interface to change wallpapers seamlessly.

```bash
#!/bin/bash

DIR="Your video path (Full. Need first time only)"
ENGINE="$HOME/.local/bin/wallpaper-engine.sh"

# Full paths (important for launcher)
ROFI="/usr/bin/rofi"
FIND="/usr/bin/find"
SED="/usr/bin/sed"
BASENAME="/usr/bin/basename"

# Get video list
mapfile -t FILES < <($FIND "$DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \))

# Create display list
OPTIONS=""
for f in "${FILES[@]}"; do
    OPTIONS+="$($BASENAME "$f")\n"
done

# Show rofi menu
CHOICE=$(echo -e "$OPTIONS" | $ROFI -dmenu -p "LiveWall")

# Exit if cancelled
[ -z "$CHOICE" ] && exit 0

# Match selected file
for f in "${FILES[@]}"; do
    if [[ "$($BASENAME "$f")" == "$CHOICE" ]]; then
        SELECTED="$f"
        break
    fi
done

# Replace VIDEO path in engine script
$SED -i "s|^VIDEO=.*|VIDEO=\"$SELECTED\"|" "$ENGINE"

# Restart wallpaper system
pkill mpvpaper 2>/dev/null
pkill wallpaper-engine.sh 2>/dev/null

nohup "$ENGINE" >/dev/null 2>&1 &

exit 0
```

### 4. Make Scripts Executable
Run the following commands to ensure your machine can seamlessly execute your scripts:

```bash
chmod +x ~/.local/bin/wallpaper-engine.sh
chmod +x ~/.local/bin/wallpaper-picker.sh
```

### 5. Final Integration (Hyprland Config)
To launch the wallpaper engine when you log in, and grant yourself a hotkey to switch the backgrounds, append the following to your `~/.config/hypr/hyprland.conf`:

```conf
# Auto-start wallpaper engine daemon on login
exec-once = ~/.local/bin/wallpaper-engine.sh

# Bind a shortcut to open the picker (e.g., SUPER + W)
bind = SUPER, W, exec, ~/.local/bin/wallpaper-picker.sh
```

Additionally, you can add manual pause and kill controls to your keybindings (typically located in `~/.config/hypr/hyprland/keybinds.conf` or directly in your `hyprland.conf`):

```conf
# Manual pause/play control for the live wallpaper
bind = SUPER, P, exec, echo '{ "command": ["cycle", "pause"] }' | socat - /tmp/mpvpaper-socket

# Completely kill the wallpaper engine if needed
bind = SUPER+Alt, P, exec, pkill mpvpaper
```

##  How It Works Behind The Scenes
1. **The Observer**: The `wallpaper-engine.sh` script runs continuously in the background. It utilizes native `hyprctl` to read the active window state every half second. If a window is spawned on top of the desktop, it acts quickly to send a dynamic `pause` command to the wallpaper (`mpvpaper`) via the IPC wrapper `socat`, halting GPU usage instantly.
2. **The Selector**: The `wallpaper-picker.sh` uses standard tools (`find`, `sed`) to present user configuration dynamically. Instead of relying on a `.conf` setup, the script intelligently modifies the target variable within the core engine source code, inherently preventing race conditions and persisting chosen backgrounds without state management configs!

Enjoy your lightweight, fast, and resource-friendly live UI!

N.B: This is my first Arch project, so I'm not an expert. I'm just sharing what I've learned.

---

<div align="center">Made By <strong>Prottay</strong> for <strong>Arch btw</strong> 🐧</div>
