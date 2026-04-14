#!/bin/bash

# Popup de controles MPD em estilo dock (Wofi)

set -euo pipefail

if ! command -v mpc >/dev/null 2>&1; then
    notify-send "MPD" "mpc nao encontrado" >/dev/null 2>&1 || true
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    notify-send "MPD" "wofi nao encontrado" >/dev/null 2>&1 || true
    exit 1
fi

systemctl --user start mpd >/dev/null 2>&1 || true

STYLE_FILE="/tmp/wofi-mpd-dock.css"
cat > "$STYLE_FILE" <<'EOF'
window {
    background-color: rgba(22, 22, 30, 0.92);
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 18px;
}
#outer-box {
    margin: 10px;
}
#input {
    margin: 6px;
    padding: 8px 10px;
    border-radius: 10px;
    border: none;
    background-color: rgba(255, 255, 255, 0.08);
    color: #ffffff;
}
#scroll {
    margin: 6px;
}
#entry {
    padding: 10px 14px;
    margin: 4px;
    border-radius: 12px;
    background-color: rgba(255, 255, 255, 0.06);
    color: #f4f4f4;
}
#entry:selected {
    background: linear-gradient(90deg, rgba(233, 84, 32, 0.92), rgba(255, 120, 50, 0.92));
    color: #ffffff;
}
EOF

choice="$(printf '%s\n' \
    '  Anterior' \
    '  Play/Pause' \
    '  Proxima' \
    '  Stop' \
    '󰒮  Abrir ncmpcpp' \
    | wofi --dmenu --prompt 'MPD Dock' --insensitive --width 420 --height 320 --location top --style "$STYLE_FILE")"

[ -z "${choice:-}" ] && exit 0

case "$choice" in
    '  Anterior')
        mpc prev >/dev/null 2>&1 || true
        ;;
    '  Play/Pause')
        mpc toggle >/dev/null 2>&1 || true
        ;;
    '  Proxima')
        mpc next >/dev/null 2>&1 || true
        ;;
    '  Stop')
        mpc stop >/dev/null 2>&1 || true
        ;;
    '󰒮  Abrir ncmpcpp')
        foot -e ncmpcpp >/dev/null 2>&1 &
        ;;
esac

pkill -RTMIN+10 waybar >/dev/null 2>&1 || true
