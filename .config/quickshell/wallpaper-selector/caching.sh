#!/usr/bin/env bash

export QS_CACHE_DIR="$HOME/.cache/quickshell"
export QS_STATE_DIR="$HOME/.local/state/quickshell"
export QS_RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
export QS_LOG_DIR="$QS_RUN_DIR/logs"

mkdir -p "$QS_CACHE_DIR" "$QS_STATE_DIR" "$QS_RUN_DIR" "$QS_LOG_DIR"

qs_ensure_cache() {
    local widget_name="$1"
    local widget_upper
    widget_upper=$(printf '%s' "$widget_name" | tr '[:lower:]' '[:upper:]')

    local widget_cache="$QS_CACHE_DIR/$widget_name"
    local widget_state="$QS_STATE_DIR/$widget_name"
    local widget_run="$QS_RUN_DIR/$widget_name"

    mkdir -p "$widget_cache" "$widget_state" "$widget_run"

    export "QS_CACHE_${widget_upper}=$widget_cache"
    export "QS_STATE_${widget_upper}=$widget_state"
    export "QS_RUN_${widget_upper}=$widget_run"
}
