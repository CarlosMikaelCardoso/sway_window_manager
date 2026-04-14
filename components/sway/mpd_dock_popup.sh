#!/bin/bash

# Popup de controles MPD em estilo dock

set -euo pipefail

SINGLE_INSTANCE=false
for arg in "$@"; do
    case "$arg" in
        --single-instance)
            SINGLE_INSTANCE=true
            ;;
    esac
done

LOCK_FILE="/tmp/mpd_dock_popup.lock"
if [ "$SINGLE_INSTANCE" = true ]; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        exit 0
    fi
fi

if ! command -v mpc >/dev/null 2>&1; then
    notify-send "MPD" "mpc nao encontrado" >/dev/null 2>&1 || true
    exit 1
fi

if ! command -v yad >/dev/null 2>&1; then
    notify-send "MPD" "yad nao encontrado. Instale com: sudo apt install yad" >/dev/null 2>&1 || true
    exit 1
fi

systemctl --user start mpd >/dev/null 2>&1 || true

STYLE_FILE="/tmp/yad-mpd-dock.css"
cat > "$STYLE_FILE" <<'CSS'
* {
    font-family: "Ubuntu", "Font Awesome 6 Free", sans-serif;
    font-size: 16px;
}
window, dialog {
    background: rgba(20, 20, 28, 0.92);
    border-radius: 22px;
    border: 1px solid rgba(255, 255, 255, 0.18);
}
button {
    background: rgba(255, 255, 255, 0.08);
    color: #f4f4f4;
    border-radius: 14px;
    border: 1px solid rgba(255, 255, 255, 0.12);
    padding: 10px 16px;
}
button:hover {
    background: rgba(233, 84, 32, 0.92);
    color: #ffffff;
}
label {
    color: #ffffff;
}
CSS

CURRENT="$(mpc current -f '%artist% - %title%' 2>/dev/null || true)"
if [ -n "${CURRENT:-}" ] && [ "${#CURRENT}" -gt 48 ]; then
    CURRENT="${CURRENT:0:45}..."
fi

PROMPT='MPD Dock'
if [ -n "${CURRENT:-}" ]; then
    PROMPT="MPD Dock | $CURRENT"
fi

yad --center --on-top --undecorated --skip-taskbar --borders=20 \
    --title="MPD Dock" \
    --text="$PROMPT" \
    --window-icon="multimedia-player" \
    --fixed --width=640 --height=170 \
    --css="$STYLE_FILE" \
    --button="  Anterior:10" \
    --button="  Play/Pause:20" \
    --button="  Proxima:30" \
    --button="  Stop:40" \
    --button="󰒮  ncmpcpp:50" \
    --button="Fechar:1"

ACTION_CODE=$?

case "$ACTION_CODE" in
    10)
        mpc prev >/dev/null 2>&1 || true
        ;;
    20)
        mpc toggle >/dev/null 2>&1 || true
        ;;
    30)
        mpc next >/dev/null 2>&1 || true
        ;;
    40)
        mpc stop >/dev/null 2>&1 || true
        ;;
    50)
        foot -e ncmpcpp >/dev/null 2>&1 &
        ;;
esac

pkill -RTMIN+10 waybar >/dev/null 2>&1 || true
