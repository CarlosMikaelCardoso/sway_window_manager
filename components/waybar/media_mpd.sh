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

RAW_FILE="$(mpc current -f '%file%' 2>/dev/null || true)"
TITLE="$(mpc current -f '%title%' 2>/dev/null || true)"
ARTIST="$(mpc current -f '%artist%' 2>/dev/null || true)"

if [ -z "$TITLE" ] && [ -n "$RAW_FILE" ]; then
    TITLE="$(basename "$RAW_FILE")"
    TITLE="${TITLE%.*}"                       # remove extensão
    TITLE="${TITLE#*. }"                      # remove prefixo tipo "47. "
    TITLE="$(printf '%s' "$TITLE" | sed -E 's/-[A-Za-z0-9_-]{8,}$//')"  # remove sufixo ID
fi

STATE_LINE="$(mpc status | sed -n '2p' || true)"
CURRENT="$(mpc current -f '%artist% - %title%' 2>/dev/null || true)"

if [ -z "${TITLE:-}" ]; then
    TITLE="Nenhuma Mídia"
    ARTIST="MPD Parado"
    CURRENT="$(mpc current -f '%file%' 2>/dev/null || true)"
fi

if [ -z "${TITLE:-}" ]; then
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
    ICON="ㅤ"
fi

if [ "${#TITLE}" -gt 42 ]; then
    TITLE="${TITLE:0:39}..."
fi

TEXT="$ICON $TITLE"
    TOOLTIP="MPD
    Artista: $ARTIST
    Musica: $TITLE
    Clique: popup dock de controle 
    Botao direito: ncmpcpp
    Scroll: proxima/anterior"

if command -v jq >/dev/null 2>&1; then
    jq -cn --arg text "$TEXT" --arg tooltip "$TOOLTIP" --arg class "$CLASS" '{text:$text, tooltip:$tooltip, class:$class}'
else
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
fi
