#!/bin/bash

# CPU custom para Waybar (JSON)

set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway-cpu"
STATE_FILE="$STATE_DIR/state"
mkdir -p "$STATE_DIR"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE_TOTAL=$((idle + iowait))

if [ -f "$STATE_FILE" ]; then
    read -r LAST_TOTAL LAST_IDLE < "$STATE_FILE" || true
else
    LAST_TOTAL=$TOTAL
    LAST_IDLE=$IDLE_TOTAL
fi

DELTA_TOTAL=$((TOTAL - LAST_TOTAL))
DELTA_IDLE=$((IDLE_TOTAL - LAST_IDLE))
if [ "$DELTA_TOTAL" -le 0 ]; then
    USAGE=0
else
    USAGE=$((100 * (DELTA_TOTAL - DELTA_IDLE) / DELTA_TOTAL))
fi

echo "$TOTAL $IDLE_TOTAL" > "$STATE_FILE"

echo "{\"text\":\" ${USAGE}%\",\"tooltip\":\"Uso de CPU: ${USAGE}%\"}"
