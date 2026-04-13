#!/bin/bash

# --- INÍCIO DO CÓDIGO DO GUIA DE ATALHOS ---

# Verifica se o zenity está instalado, se não, instala (necessário para a janela de ajuda)
if ! command -v zenity &> /dev/null; then
    sudo apt update && sudo apt install -y zenity
fi

# Texto formatado com os atalhos baseados na sua configuração
TEXTO="
<b>Sway WM - Guia Rápido de Atalhos (Estilo Ubuntu)</b>

<b>SISTEMA E NAVEGAÇÃO:</b>
• <b>Super + Enter</b>          → Abrir Terminal (foot)
• <b>Super + D</b>              → Menu de Aplicativos (wofi)
• <b>Super + Q</b>              → Fechar Janela Atual
• <b>Super + Setas</b>          → Mudar foco entre janelas
• <b>Super + Shift + C</b>    → Recarregar Configurações
• <b>Super + Shift + E</b>    → Menu de Saída (Log out)

<b>CONFIGURAÇÕES (Digite no Terminal):</b>
• <b>nmtui</b>                  → Configurar Wi-Fi e Rede
• <b>pavucontrol</b>            → Configurações de Som/Volume
• <b>blueman-manager</b>        → Gerenciar Bluetooth
• <b>wdisplays</b>              → Configurar Monitores/Resolução

<b>DICA:</b>
O arquivo de configuração principal está em: 
<i>~/.config/sway/config</i>
"

# Exibe a janela de informações
zenity --info --title="Atalhos do Sistema" --text="$TEXTO" --width=400 --ok-label="Entendi!"

# --- FIM DO CÓDIGO DO GUIA DE ATALHOS ---
