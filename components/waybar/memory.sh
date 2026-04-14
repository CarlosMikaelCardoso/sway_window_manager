#!/bin/bash

# Memoria custom para Waybar (JSON)

set -euo pipefail

TOTAL_KB="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
AVAILABLE_KB="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
USED_KB=$((TOTAL_KB - AVAILABLE_KB))

if [ "$TOTAL_KB" -gt 0 ]; then
    USED_PCT=$((100 * USED_KB / TOTAL_KB))
else
    USED_PCT=0
fi

USED_GB="$(awk -v v="$USED_KB" 'BEGIN { printf "%.1f", v/1024/1024 }')"
TOTAL_GB="$(awk -v v="$TOTAL_KB" 'BEGIN { printf "%.1f", v/1024/1024 }')"

echo "{\"text\":\"🎟 ${USED_PCT}%\",\"tooltip\":\"RAM: ${USED_GB}G / ${TOTAL_GB}G\"}"
