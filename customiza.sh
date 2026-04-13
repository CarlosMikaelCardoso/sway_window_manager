#!/bin/bash

# --- INÍCIO DA CUSTOMIZAÇÃO VISUAL SWAY/WAYBAR ---

echo "Customizando Sway e Waybar com estilo amigável..."

# 1. Instalar dependências de ícones e fontes (essencial para a Waybar não ficar com quadrados)
sudo apt update
sudo apt install -y fonts-font-awesome fonts-noto-color-emoji fonts-liberation

# 2. Criar pastas de config
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar

# 3. Gerar configuração da Waybar (Estilo Ubuntu)
cat <<EOF > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "tray"],
    
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
    },
    "clock": {
        "format": "{:%d/%m/%Y - %H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "🔇",
        "format-icons": {
            "default": ["", "", ""]
        }
    },
    "cpu": { "format": " {usage}%" },
    "memory": { "format": " {}%" }
}
EOF

# 4. Estilizar a Waybar (CSS para parecer com o Ubuntu)
cat <<EOF > ~/.config/waybar/style.css
* {
    font-family: "Ubuntu", "Font Awesome 6 Free", sans-serif;
    font-size: 14px;
}
window#waybar {
    background-color: rgba(48, 10, 36, 0.95); /* Roxo escuro Ubuntu */
    border-bottom: 2px solid #E95420; /* Laranja Ubuntu */
    color: #ffffff;
}
#workspaces button {
    padding: 0 5px;
    color: #ffffff;
}
#workspaces button.focused {
    background-color: #E95420;
    border-radius: 4px;
}
#clock, #pulseaudio, #network, #cpu, #memory, #tray {
    padding: 0 10px;
}
EOF

# 5. Configuração do Sway integrada
cat <<EOF > ~/.config/sway/config
set \$mod Mod4
set \$term foot
set \$menu wofi --show drun --allow-images

# Cores Ubuntu
client.focused #E95420 #E95420 #ffffff #E95420
output * bg /usr/share/backgrounds/warty-final-ubuntu.png fill

# Atalhos
bindsym \$mod+Return exec \$term
bindsym \$mod+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair?' -b 'Sim' 'swaymsg exit'

# Iniciar Barra automaticamente
bar {
    swaybar_command waybar
}

# Bordas arredondadas (simuladas por gaps)
gaps inner 8
gaps outer 2
smart_borders on
EOF

echo "Customização aplicada! Aperte Super+Shift+C dentro do Sway para atualizar."

# --- FIM DO SCRIPT ---
