#!/bin/bash

# Popup de controles MPD em estilo dock (macOS / Control Center)

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
    font-family: "-apple-system", "BlinkMacSystemFont", "Segoe UI", "Ubuntu", "Font Awesome 6 Free", sans-serif;
}
#yad-dialog-window {
    background-color: rgba(24, 24, 24, 0.95);
    border-radius: 32px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}
button {
    background-color: rgba(255, 255, 255, 0.08);
    color: #ffffff;
    border-radius: 24px;
    border: none;
    padding: 16px 20px;
    margin: 0 6px;
    font-size: 22px;
    transition: all 0.2s ease-in-out;
}
button:hover {
    background-color: rgba(255, 255, 255, 0.2);
    border-radius: 24px;
}
label {
    color: #ffffff;
}
CSS

TITLE="$(mpc current -f '%title%' 2>/dev/null || true)"
ARTIST="$(mpc current -f '%artist%' 2>/dev/null || true)"

if [ -z "$TITLE" ]; then
    TITLE="Nenhuma Mídia"
    ARTIST="MPD Parado"
fi

if [ -n "${TITLE:-}" ] && [ "${#TITLE}" -gt 40 ]; then
    TITLE="${TITLE:0:37}..."
fi

if [ -n "${ARTIST:-}" ] && [ "${#ARTIST}" -gt 40 ]; then
    ARTIST="${ARTIST:0:37}..."
fi

STATE_LINE="$(mpc status | sed -n '2p' || true)"
PLAY_PAUSE_ICON=""
if printf '%s' "$STATE_LINE" | grep -q '\[paused\]'; then
    PLAY_PAUSE_ICON=""
elif ! printf '%s' "$STATE_LINE" | grep -q '\[playing\]'; then
    PLAY_PAUSE_ICON=""
fi

# Formatação Pango: Titulo grande, artista menor e cinza claro
TEXT="<span font='18' weight='bold' color='#ffffff'>$TITLE</span>\n<span font='14' color='#a1a1a6'>$ARTIST</span>"

# Determinar a posição do popup para aparecer abaixo do botão central da Waybar
if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    (
        for _ in {1..20}; do
            if swaymsg -t get_tree | grep -E -q '"app_id": "mpd-popup"|"class": "mpd-popup"'; then
                WIDTH=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect.width')
                WIN_WIDTH=340
                POS_X=$(( (WIDTH - WIN_WIDTH) / 2 ))
                POS_Y=45 # Ajuste para ficar logo abaixo da Waybar
                swaymsg "[app_id=\"mpd-popup\"] floating enable, move position $POS_X $POS_Y" >/dev/null 2>&1 || true
                swaymsg "[class=\"mpd-popup\"] floating enable, move position $POS_X $POS_Y" >/dev/null 2>&1 || true
                break
            fi
            sleep 0.1
        done
    ) &
fi

set +e
yad --class="mpd-popup" --on-top --undecorated --skip-taskbar --borders=24 \
    --title="MPD Dock" \
    --text="$TEXT" \
    --image="multimedia-audio-player" \
    --image-on-top \
    --fixed --width=340 --height=200 \
    --css="$STYLE_FILE" \
    --button=":10" \
    --button="$PLAY_PAUSE_ICON:20" \
    --button=":30" \
    --button="🎵:50" \
    --button="✕:1"

ACTION_CODE=$?
set -e

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
    50)
        foot -e ncmpcpp >/dev/null 2>&1 &
        ;;
esac

pkill -RTMIN+10 waybar >/dev/null 2>&1 || true
