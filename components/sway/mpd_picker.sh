#!/bin/bash

# Seletor de musicas locais do MPD usando Zenity

set -euo pipefail

if ! command -v mpc >/dev/null 2>&1; then
    notify-send "MPD" "mpc nao encontrado" || true
    exit 1
fi

if ! command -v zenity >/dev/null 2>&1; then
    notify-send "MPD" "zenity nao encontrado" || true
    exit 1
fi

systemctl --user start mpd >/dev/null 2>&1 || true

SONGS="$(mpc listall 2>/dev/null || true)"
if [ -z "${SONGS:-}" ]; then
    mpc update >/dev/null 2>&1 || true
    notify-send "MPD" "Biblioteca vazia. Coloque musicas em ~/Musicas e tente novamente." || true
    exit 0
fi

CHOICE="$(printf '%s\n' "$SONGS" | zenity --list --title='Escolher musica' --text='Selecione uma faixa para tocar' --column='Faixa' --height=520 --width=900 2>/dev/null || true)"

if [ -z "${CHOICE:-}" ]; then
    exit 0
fi

mpc clear >/dev/null 2>&1 || true
mpc add "$CHOICE" >/dev/null 2>&1 || true
mpc play >/dev/null 2>&1 || true

# Aguarda a estabilização do estado do MPD antes de forçar o refresh da barra
sleep 0.2
pkill -RTMIN+10 waybar >/dev/null 2>&1 || true
mpc refresh >/dev/null 2>&1 || true
