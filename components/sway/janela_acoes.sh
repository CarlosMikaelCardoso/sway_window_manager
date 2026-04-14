#!/bin/bash

# Menu de ações para a janela atual no Sway

set -euo pipefail

if ! command -v swaymsg >/dev/null 2>&1; then
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    # Fallback simples sem menu
    swaymsg fullscreen toggle >/dev/null
    exit 0
fi

OPCAO="$(printf '%s\n' \
    'Trazer para frente' \
    'Fechar janela' \
    'Esconder janela (scratchpad)' \
    'Mostrar janela escondida' \
    'Maximizar/Restaurar' \
    'Alternar sobreposicao (flutuante)' \
    | wofi --dmenu --insensitive --prompt 'Acoes da Janela' --lines 8)"

case "$OPCAO" in
    'Trazer para frente')
        CON_ID="$(swaymsg -t get_tree | jq -r '.. | objects | select(.focused? == true and (.type? == "con" or .type? == "floating_con")) | .id' | head -n1)"
        if [ -n "$CON_ID" ]; then
            MARK="__raise_${CON_ID}"
            swaymsg "[con_id=$CON_ID] mark $MARK" >/dev/null
            swaymsg "[con_mark=$MARK] move scratchpad" >/dev/null
            swaymsg "[con_mark=$MARK] scratchpad show" >/dev/null
            swaymsg "[con_mark=$MARK] focus" >/dev/null
            swaymsg "[con_mark=$MARK] unmark $MARK" >/dev/null
        fi
        ;;
    'Fechar janela')
        swaymsg kill >/dev/null
        ;;
    'Esconder janela (scratchpad)')
        swaymsg move scratchpad >/dev/null
        ;;
    'Mostrar janela escondida')
        swaymsg scratchpad show >/dev/null
        ;;
    'Maximizar/Restaurar')
        swaymsg fullscreen toggle >/dev/null
        ;;
    'Alternar sobreposicao (flutuante)')
        swaymsg floating toggle >/dev/null
        ;;
esac
