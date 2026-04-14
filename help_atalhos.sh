#!/bin/bash
TEXTO="<b>ATALHOS:</b>\n• Super+Enter: Terminal\n• Super+D: Menu\n• Super+Q: Fechar\n• Super+Ctrl+B: Mostrar/Ocultar Waybar\n• Super+H: Ajuda"
zenity --info --title="Sway Help" --text="$TEXTO"
