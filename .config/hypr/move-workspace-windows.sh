#!/usr/bin/env bash

set -euo pipefail

target_workspace="${1:-}"
dry_run=0

if [[ "${2:-}" == "--dry-run" ]]; then
    dry_run=1
fi

if [[ -z "$target_workspace" ]]; then
    exit 1
fi

notify() {
    hyprctl notify 1 3500 0 "$1" >/dev/null 2>&1 || true
}

dispatch() {
    local expr="$1"

    if (( dry_run )); then
        printf 'hyprctl dispatch %q\n' "$expr"
        return
    fi

    hyprctl dispatch "$expr" >/dev/null
}

declare -A X Y W H
declare -A NODE_TYPE NODE_ADDR NODE_FIRST NODE_SECOND

node_counter=0
last_node=""
step_focus=()
step_move=()

new_leaf() {
    local address="$1"
    local node="leaf_$((++node_counter))"
    NODE_TYPE["$node"]="leaf"
    NODE_ADDR["$node"]="$address"
    last_node="$node"
}

new_split() {
    local first="$1"
    local second="$2"
    local node="split_$((++node_counter))"
    NODE_TYPE["$node"]="split"
    NODE_FIRST["$node"]="$first"
    NODE_SECOND["$node"]="$second"
    last_node="$node"
}

seed_address() {
    local node="$1"

    if [[ "${NODE_TYPE[$node]}" == "leaf" ]]; then
        printf '%s\n' "${NODE_ADDR[$node]}"
        return
    fi

    seed_address "${NODE_FIRST[$node]}"
}

emit_steps() {
    local node="$1"

    if [[ "${NODE_TYPE[$node]}" == "leaf" ]]; then
        return
    fi

    local first_seed
    local second_seed
    first_seed="$(seed_address "${NODE_FIRST[$node]}")"
    second_seed="$(seed_address "${NODE_SECOND[$node]}")"

    step_focus+=("$first_seed")
    step_move+=("$second_seed")

    emit_steps "${NODE_FIRST[$node]}"
    emit_steps "${NODE_SECOND[$node]}"
}

find_split() {
    local axis="$1"
    local -n out_first_ref="$2"
    local -n out_second_ref="$3"
    shift 3

    local ids=("$@")
    local starts=()
    local ends=()
    local split
    local address

    for address in "${ids[@]}"; do
        if [[ "$axis" == "vertical" ]]; then
            starts+=("${X[$address]}")
            ends+=("$((X[$address] + W[$address]))")
        else
            starts+=("${Y[$address]}")
            ends+=("$((Y[$address] + H[$address]))")
        fi
    done

    local candidates=()
    mapfile -t candidates < <(printf '%s\n' "${starts[@]}" "${ends[@]}" | sort -n -u)

    if (( ${#candidates[@]} < 3 )); then
        return 1
    fi

    local idx
    for (( idx = 1; idx < ${#candidates[@]} - 1; idx++ )); do
        split="${candidates[$idx]}"

        local left=()
        local right=()
        local valid=1
        local start
        local end

        for address in "${ids[@]}"; do
            if [[ "$axis" == "vertical" ]]; then
                start="${X[$address]}"
                end="$((X[$address] + W[$address]))"
            else
                start="${Y[$address]}"
                end="$((Y[$address] + H[$address]))"
            fi

            if (( end <= split )); then
                left+=("$address")
            elif (( start >= split )); then
                right+=("$address")
            else
                valid=0
                break
            fi
        done

        if (( valid && ${#left[@]} > 0 && ${#right[@]} > 0 )); then
            out_first_ref=("${left[@]}")
            out_second_ref=("${right[@]}")
            return 0
        fi
    done

    return 1
}

build_tree() {
    local ids=("$@")

    if (( ${#ids[@]} == 1 )); then
        new_leaf "${ids[0]}"
        return
    fi

    local first=()
    local second=()

    if ! find_split vertical first second "${ids[@]}" && ! find_split horizontal first second "${ids[@]}"; then
        return 1
    fi

    local first_node
    local second_node
    build_tree "${first[@]}" || return 1
    first_node="$last_node"
    build_tree "${second[@]}" || return 1
    second_node="$last_node"

    new_split "$first_node" "$second_node"
}

active_workspace_json="$(hyprctl -j activeworkspace)"
clients_json="$(hyprctl -j clients)"

source_workspace="$(jq -r '.id' <<<"$active_workspace_json")"
target_windows="$(jq -r --argjson target "$target_workspace" '[.[] | select(.mapped and .workspace.id == $target)] | length' <<<"$clients_json")"

if [[ "$source_workspace" == "$target_workspace" ]]; then
    exit 0
fi

if (( target_windows > 0 )); then
    notify "Target workspace $target_workspace is not empty."
    exit 1
fi

tiled_addresses=()
floating_addresses=()

while IFS=$'\t' read -r address floating x y w h; do
    [[ -n "$address" ]] || continue

    if [[ "$floating" == "1" ]]; then
        floating_addresses+=("$address")
    else
        tiled_addresses+=("$address")
        X["$address"]="$x"
        Y["$address"]="$y"
        W["$address"]="$w"
        H["$address"]="$h"
    fi
done < <(
    jq -r \
        --argjson source "$source_workspace" \
        '.[]
        | select(.mapped and .workspace.id == $source)
        | [
            .address,
            (if .floating then "1" else "0" end),
            (.at[0] | tostring),
            (.at[1] | tostring),
            (.size[0] | tostring),
            (.size[1] | tostring)
          ]
        | @tsv' <<<"$clients_json"
)

if (( ${#tiled_addresses[@]} == 0 && ${#floating_addresses[@]} == 0 )); then
    exit 0
fi

if (( ${#tiled_addresses[@]} > 0 )); then
    build_tree "${tiled_addresses[@]}" || {
        notify "Could not infer the tiled layout for workspace $source_workspace."
        exit 1
    }
    root_node="$last_node"

    initial_tiled_address="$(seed_address "$root_node")"
    emit_steps "$root_node"

    dispatch "hl.dsp.focus({ workspace = '$target_workspace' })"
    dispatch "hl.dsp.window.move({ workspace = '$target_workspace', follow = false, window = 'address:$initial_tiled_address' })"

    for idx in "${!step_move[@]}"; do
        dispatch "hl.dsp.focus({ window = 'address:${step_focus[$idx]}' })"
        dispatch "hl.dsp.window.move({ workspace = '$target_workspace', follow = false, window = 'address:${step_move[$idx]}' })"
    done
fi

for address in "${floating_addresses[@]}"; do
    dispatch "hl.dsp.window.move({ workspace = '$target_workspace', follow = false, window = 'address:$address' })"
done

if (( ${#tiled_addresses[@]} > 0 )); then
    dispatch "hl.dsp.focus({ workspace = '$source_workspace' })"
fi

notify "Moved workspace $source_workspace windows to workspace $target_workspace."
