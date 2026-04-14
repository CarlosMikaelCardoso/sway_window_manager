#!/bin/bash

# Volume custom para Waybar (JSON)

set -euo pipefail

if ! command -v pactl >/dev/null 2>&1; then
    echo '{"text":"🔇 N/A","tooltip":"pactl não encontrado"}'
    exit 0
fi

VOLUME_RAW="$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1)"
MUTE_STATE="$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print tolower($2)}')"

VOLUME="$(printf '%s' "$VOLUME_RAW" | grep -oE '[0-9]+%' | head -n1 | tr -d '%')"
if [ -z "${VOLUME:-}" ]; then
    VOLUME=0
fi

if [ "$MUTE_STATE" = "yes" ] || [ "$MUTE_STATE" = "sim" ]; then
    ICON="🔇"
else
    if [ "$VOLUME" -lt 35 ]; then
        ICON=""
    elif [ "$VOLUME" -lt 70 ]; then
        ICON=""
    else
        ICON=""
    fi
fi

echo "{\"text\":\"${ICON} ${VOLUME}%\",\"tooltip\":\"Volume: ${VOLUME}%\\nMute: ${MUTE_STATE}\"}"
