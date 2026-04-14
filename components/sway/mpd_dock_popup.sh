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


# Modificação: Adicionado border-radius no CSS para visual macOS e corrigida a regra do swaymsg 
# para usar o 'title="MPD Dock"' e 'border pixel 0', garantindo que flutue e remova as bordas laranjas nativas do WM.

STYLE_FILE="/tmp/yad-mpd-dock.css"
cat > "$STYLE_FILE" <<'CSS'
* {
    font-family: "-apple-system", "BlinkMacSystemFont", "Segoe UI", "Ubuntu", "Font Awesome 6 Free", sans-serif;
}
window, dialog, box {
    background-color: rgba(20, 20, 20, 0.95) !important;
    background-image: none !important;
    border: none !important;
    border-radius: 18px !important;
}
button {
    background-color: rgba(255, 255, 255, 0.08) !important;
    color: #ffffff !important;
    border-radius: 14px !important;
    border: none !important;
    padding: 12px 18px !important;
    margin: 10px 6px !important;
    font-size: 22px !important;
    transition: all 0.2s ease-in-out !important;
}
button:hover {
    background-color: rgba(255, 255, 255, 0.2) !important;
    border-radius: 24px !important;
}
label {
    color: #ffffff !important;
    background: transparent !important;
    margin-top: 10px;
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

WIN_WIDTH=380

# Determinar a posição do popup para aparecer abaixo do botão central da Waybar
if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    WIDTH=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect.width')
    POS_X=$(( (WIDTH - WIN_WIDTH) / 2 ))
    POS_Y=45 # Ajuste para ficar logo abaixo da Waybar
    
    # Aplica regra do Sway ANTES de abrir a janela. Assim ela nasce direto no local, sem piscar no centro.
    swaymsg "for_window [title=\"MPD Dock\"] floating enable, border pixel 0, move position $POS_X $POS_Y" >/dev/null 2>&1 || true
fi


set +e
yad --class="mpd-popup" --on-top --undecorated --skip-taskbar --borders=20 \
    --title="MPD Dock" \
    --text="$TEXT" \
    --image="multimedia-audio-player" \
    --image-on-top \
    --fixed --width=$WIN_WIDTH --height=220 \
    --css="$STYLE_FILE" \
    --button=":10" \
    --button="$PLAY_PAUSE_ICON:20" \
    --button=":30" \
    --button=":50" \
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
