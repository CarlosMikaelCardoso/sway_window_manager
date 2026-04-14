#!/bin/bash

# --- CUSTOMIZAÇÃO: EXTRAS + TEMA ---

echo "🎨 Instalando extras e aplicando tema do Sway/Waybar..."

# 1. Instalar dependências extras (barra, launcher, rede, áudio, etc.)
sudo apt update
sudo apt install -y waybar wofi \
    fonts-font-awesome fonts-noto-color-emoji fonts-liberation \
    grim slurp pavucontrol blueman wdisplays network-manager-gnome \
    zenity pulseaudio-utils dunst

# 2. Criar pastas de config
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/sway

# 3. Gerar configuração da Waybar (dock flutuante)
cat <<EOF > ~/.config/waybar/config
{
    "layer": "top",
    "exclusive": false,
    "position": "top",
    "margin-top": 10,
    "margin-left": 18,
    "margin-right": 18,
    "height": 34,
    "on-sigusr1": "toggle",
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
    "memory": { "format": "🎟 {}%" }
}
EOF

# 4. Estilizar a Waybar em cards
cat <<EOF > ~/.config/waybar/style.css
* {
    font-family: "Ubuntu", "Font Awesome 6 Free", sans-serif;
    font-size: 14px;
}
window#waybar {
    background-color: rgba(0, 0, 0, 0);
    color: #ffffff;
}

#workspaces,
#clock,
#pulseaudio,
#network,
#cpu,
#memory,
#tray {
    background-color: rgba(48, 10, 36, 0.95);
    border: 1px solid rgba(233, 84, 32, 0.65);
    border-radius: 12px;
    margin: 0 4px;
    padding: 0 10px;
}

#workspaces button.focused {
    background-color: #E95420;
    border-radius: 4px;
}
EOF

# 5. Aplicar configuração temática do Sway
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
bindsym \$mod+h exec bash ~/sway/help_atalhos.sh
bindsym \$mod+Ctrl+b exec pkill -USR1 waybar

# Iniciar Barra automaticamente
bar {
    swaybar_command waybar
}

# Teclado e Mouse
input "type:keyboard" {
    xkb_layout br
}

input "type:pointer" {
    accel_profile "flat"
    pointer_accel -0.2
    tap enabled
    natural_scroll disable
}

# Apps em background
exec nm-applet --indicator
exec dunst

# Bordas arredondadas (simuladas por gaps)
gaps inner 8
gaps outer 2
smart_borders on
EOF

# 6. Script de ajuda de atalhos (fonte única: arquivo do repositório)
if [ -f "$(dirname "$0")/help_atalhos.sh" ]; then
    cp "$(dirname "$0")/help_atalhos.sh" ~/sway/help_atalhos.sh
else
    echo "⚠️ help_atalhos.sh não encontrado no repositório. Mantendo configuração atual."
fi
chmod +x ~/sway/help_atalhos.sh

echo "✅ Customização aplicada!"
echo "➡️ Use Super+Shift+C para recarregar no Sway (ou reinicie a sessão)."

# --- FIM DO SCRIPT ---
