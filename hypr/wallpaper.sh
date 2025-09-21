#!/bin/bash

# Folder where wallpapers are stored
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Ask the user to pick a file with wofi
SELECTED=$(ls "$WALLPAPER_DIR" | wofi --show dmenu -n --prompt "Select a wallpaper")

# If user cancels, exit
[ -z "$SELECTED" ] && exit 1

# Full path to the wallpaper
WALLPAPER="$WALLPAPER_DIR/$SELECTED"

# Initialize swww if not running
if ! pgrep -x swww-daemon > /dev/null; then
    swww init
fi

wal -i "$WALLPAPER"
# Apply wallpaper with a transition
swww img "$WALLPAPER" --transition-type any --transition-fps 60 --transition-duration 2



