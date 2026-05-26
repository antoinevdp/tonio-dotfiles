#!/usr/bin/env bash

hyprctl reload config-only >/dev/null 2>&1 || true
swaync-client -rs >/dev/null 2>&1 || true
cp "$HOME/.config/quickshell/Colors.qml" "$HOME/.config/quickshell/wallpaper-selector/Colors.qml" 2>/dev/null || true

if pgrep -x quickshell >/dev/null; then
    quickshell kill --path "$HOME/.config/quickshell/shell.qml" >/dev/null 2>&1 || true
    quickshell --path "$HOME/.config/quickshell/shell.qml" >/dev/null 2>&1 &
fi
