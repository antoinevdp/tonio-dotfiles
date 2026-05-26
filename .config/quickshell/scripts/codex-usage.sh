#!/usr/bin/env bash
set -euo pipefail

cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/codex-usage.json"
mkdir -p "$(dirname "$cache_file")"

fallback() {
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        printf '%s\n' '{"status":"missing-data","five_hour_used_percent":-1,"weekly_used_percent":-1,"reset_at":""}'
    fi
}

if ! command -v codex >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    fallback
    exit 0
fi

tmp_file=$(mktemp)
cleanup() {
    rm -f "$tmp_file"
    if [ -n "${CODEX_PID:-}" ]; then
        kill "$CODEX_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

coproc CODEX { codex app-server --listen stdio:// 2>/dev/null; }

printf '%s\n' '{"id":1,"method":"initialize","params":{"clientInfo":{"name":"quickshell_codex_usage","title":"Quickshell Codex Usage","version":"0.1.0"},"capabilities":{"experimentalApi":true}}}' >&"${CODEX[1]}"

if ! IFS= read -r -t 10 _ <&"${CODEX[0]}"; then
    fallback
    exit 0
fi

printf '%s\n' '{"method":"initialized"}' '{"id":2,"method":"account/rateLimits/read"}' >&"${CODEX[1]}"

deadline=$((SECONDS + 30))
while [ "$SECONDS" -lt "$deadline" ]; do
    if IFS= read -r -t 1 line <&"${CODEX[0]}"; then
        if printf '%s\n' "$line" | jq -e '.id == 2 and (.result.rateLimits != null)' >/dev/null 2>&1; then
            printf '%s\n' "$line" >"$tmp_file"
            break
        fi
    fi
done

if [ ! -s "$tmp_file" ]; then
    fallback
    exit 0
fi

jq -c '
    .result.rateLimits as $limits
    | {
        status: "ok",
        five_hour_used_percent: ($limits.primary.usedPercent // -1),
        weekly_used_percent: ($limits.secondary.usedPercent // -1),
        reset_at: (($limits.primary.resetsAt // 0) | if . > 0 then todateiso8601 else "" end),
        weekly_reset_at: (($limits.secondary.resetsAt // 0) | if . > 0 then todateiso8601 else "" end),
        plan_type: ($limits.planType // ""),
        has_credits: ($limits.credits.hasCredits // false),
        credits_balance: ($limits.credits.balance // "")
    }
' "$tmp_file" >"$cache_file"

cat "$cache_file"
