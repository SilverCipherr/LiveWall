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
