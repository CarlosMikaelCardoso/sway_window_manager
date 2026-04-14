#!/bin/bash

# Controle de volume com update imediato da Waybar
# Uso: volume_control.sh up|down|mute

set -euo pipefail

ACTION="${1:-up}"
STEP="5%"

update_waybar_audio() {
    pkill -RTMIN+9 waybar >/dev/null 2>&1 || true
}

if command -v wpctl >/dev/null 2>&1; then
    case "$ACTION" in
        up)
            wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "${STEP}+" >/dev/null 2>&1 || true
            ;;
        down)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}-" >/dev/null 2>&1 || true
            ;;
        mute)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1 || true
            ;;
    esac
else
    case "$ACTION" in
        up)
            pactl set-sink-volume @DEFAULT_SINK@ +"$STEP" >/dev/null 2>&1 || true
            ;;
        down)
            pactl set-sink-volume @DEFAULT_SINK@ -"$STEP" >/dev/null 2>&1 || true
            ;;
        mute)
            pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1 || true
            ;;
    esac
fi

update_waybar_audio
