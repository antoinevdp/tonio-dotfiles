#!/usr/bin/env bash
set -euo pipefail

export WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

SELECTOR_DIR="$HOME/.config/quickshell/wallpaper-selector"

source "$SELECTOR_DIR/caching.sh"
qs_ensure_cache "wallpaper_picker"

mkdir -p "$QS_CACHE_WALLPAPER_PICKER/thumbs"
echo "run" > "$QS_RUN_WALLPAPER_PICKER/ddg_search_control"

(
    export MAGICK_THREAD_LIMIT=1
    manifest="$QS_CACHE_WALLPAPER_PICKER/thumbs/.manifest"
    touch "$manifest"

    for img in "$WALLPAPER_DIR"/*; do
        [ -f "$img" ] || continue
        filename=$(basename "$img")
        ext="${filename##*.}"
        ext="${ext,,}"

        case "$ext" in
            jpg|jpeg|png|gif|webp)
                thumb="$QS_CACHE_WALLPAPER_PICKER/thumbs/$filename"
                if [ ! -f "$thumb" ]; then
                    magick "$img" -resize x420 -quality 70 "$thumb" >/dev/null 2>&1 || true
                    printf '%s\n' "$filename" >> "$manifest"
                fi
                ;;
            mp4|mkv|mov|webm)
                thumb="$QS_CACHE_WALLPAPER_PICKER/thumbs/000_$filename"
                if [ ! -f "$thumb" ]; then
                    ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -threads 1 -f image2 -q:v 2 "$thumb" >/dev/null 2>&1 || true
                    printf '000_%s\n' "$filename" >> "$manifest"
                fi
                ;;
        esac
    done
) >/dev/null 2>&1 &

if quickshell list --path "$SELECTOR_DIR" | grep -q '^Instance '; then
    quickshell kill --path "$SELECTOR_DIR"
else
    quickshell --path "$SELECTOR_DIR" >/dev/null 2>&1 &
fi
