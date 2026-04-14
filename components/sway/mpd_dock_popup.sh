# --- INÍCIO DO CÓDIGO ---
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
    font-family: "SF Pro Display", "Segoe UI", "Ubuntu", "Font Awesome 6 Free", sans-serif;
    background-color: transparent !important;
    color: #ffffff !important;
}
window, dialog, box {
    background-color: rgba(24, 25, 28, 0.92) !important;
    border-radius: 20px !important;
    border: 1px solid rgba(255, 255, 255, 0.16) !important;
    box-shadow: 0 18px 36px rgba(0, 0, 0, 0.45) !important;
}
label {
    background-color: transparent !important;
    border: none !important;
}
button {
    background-image: none !important;
    background-color: rgba(255, 255, 255, 0.12) !important;
    border: 1px solid rgba(255, 255, 255, 0.15) !important;
    border-radius: 14px !important;
    padding: 12px 16px !important;
    margin: 8px 5px !important;
    font-size: 20px !important;
}
button:hover {
    background-color: rgba(255, 255, 255, 0.22) !important;
    border-color: rgba(255, 255, 255, 0.35) !important;
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

PROGRESS=""
if printf '%s' "$STATE_LINE" | grep -q '\['; then
    TIME_INFO="$(printf '%s' "$STATE_LINE" | awk '{print $3}')"
    PCT_INFO="$(printf '%s' "$STATE_LINE" | awk '{print $4}')"
    PROGRESS="\n\n<span font='11' color='#888888'>$TIME_INFO   $PCT_INFO</span>"
fi

# Formatação Pango: Titulo grande, artista menor e cinza claro
TEXT="<span font='18' weight='bold' color='#ffffff'>$TITLE</span>\n<span font='14' color='#a1a1a6'>$ARTIST</span>$PROGRESS"

WIN_WIDTH=420
WIN_HEIGHT=190
POS_X=0
POS_Y=46

if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    OUTPUT_RECT_JSON="$(swaymsg -t get_outputs | jq -c '.[] | select(.focused) | .rect' | head -n1)"
    if [ -n "${OUTPUT_RECT_JSON:-}" ] && [ "$OUTPUT_RECT_JSON" != "null" ]; then
        OUT_X="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.x')"
        OUT_Y="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.y')"
        OUT_W="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.width')"
        POS_X=$(( OUT_X + (OUT_W - WIN_WIDTH) / 2 ))
        POS_Y=$(( OUT_Y + 44 ))
    fi
fi

set +e
GTK_THEME=Adwaita:dark yad --class="mpd-popup" --name="mpd-popup" --on-top --undecorated --skip-taskbar --borders=16 \
    --title="MPD Dock" \
    --text="$TEXT" \
    --fixed --width=$WIN_WIDTH --height=$WIN_HEIGHT \
    --css="$STYLE_FILE" \
    --button=":10" \
    --button="$PLAY_PAUSE_ICON:20" \
    --button=":30" \
    --button=":50" \
    --button="✕:1" &

YAD_PID=$!

if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    # Reposiciona assim que o container nasce para evitar quebrar o layout em tiling.
    for _ in $(seq 1 20); do
        WIN_ID="$(swaymsg -t get_tree | jq -r --argjson pid "$YAD_PID" '
          .. | objects
          | select(.pid? == $pid and .name? == "MPD Dock")
          | .id
        ' | head -n1)"

        if [ -n "${WIN_ID:-}" ] && [ "$WIN_ID" != "null" ]; then
            swaymsg "[con_id=$WIN_ID] floating enable, sticky enable, border none, move position $POS_X $POS_Y, resize set $WIN_WIDTH $WIN_HEIGHT" >/dev/null 2>&1 || true
            break
        fi
        sleep 0.03
    done
fi

wait "$YAD_PID"
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
# --- FIM DO CÓDIGO ---