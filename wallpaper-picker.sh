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