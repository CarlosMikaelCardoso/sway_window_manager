#!/bin/bash

# Modulo MPD para Waybar (mostra faixa atual e estado)

set -euo pipefail

if ! command -v mpc >/dev/null 2>&1; then
    echo '{"text":" MPD N/A","tooltip":"mpc nao encontrado"}'
    exit 0
fi

if ! mpc status >/dev/null 2>&1; then
    echo '{"text":" MPD off","class":"stopped","tooltip":"MPD desligado\nClique para abrir controles"}'
    exit 0
fi

STATE_LINE="$(mpc status | sed -n '2p' || true)"
CURRENT="$(mpc current -f '%artist% - %title%' 2>/dev/null || true)"

if [ -z "${CURRENT:-}" ]; then
    CURRENT="$(mpc current -f '%file%' 2>/dev/null || true)"
fi

if [ -z "${CURRENT:-}" ]; then
    echo '{"text":" Sem musica","class":"stopped","tooltip":"Clique para abrir popup dock"}'
    exit 0
fi

CLASS="stopped"
ICON=""
if printf '%s' "$STATE_LINE" | grep -q '\[playing\]'; then
    CLASS="playing"
    ICON=""
elif printf '%s' "$STATE_LINE" | grep -q '\[paused\]'; then
    CLASS="paused"
    ICON=""
fi

if [ "${#CURRENT}" -gt 42 ]; then
    CURRENT="${CURRENT:0:39}..."
fi

TEXT="$ICON $CURRENT"
TOOLTIP="MPD\n$CURRENT\nClique: popup dock de controle\nBotao direito: ncmpcpp\nScroll: proxima/anterior"

if command -v jq >/dev/null 2>&1; then
    jq -cn --arg text "$TEXT" --arg tooltip "$TOOLTIP" --arg class "$CLASS" '{text:$text, tooltip:$tooltip, class:$class}'
else
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
fi
