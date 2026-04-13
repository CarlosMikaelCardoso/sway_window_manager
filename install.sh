# --- INÍCIO DO CÓDIGO MODIFICADO: install.sh ATUALIZADO ---

#!/bin/bash

echo "🚀 Atualizando o instalador para a versão de produção..."

# 1. Instalação de pacotes (Base completa)
sudo apt update
sudo apt install -y sway waybar wofi swaybg swayidle swaylock foot wlogout \
    fonts-font-awesome fonts-noto-color-emoji fonts-liberation \
    grim slurp pavucontrol blueman wdisplays network-manager-gnome \
    zenity pulseaudio-utils

# 2. Estrutura de pastas
mkdir -p ~/.config/sway ~/.config/waybar ~/.config/foot

# 3. Gerando ~/.config/sway/config
cat <<EOF > ~/.config/sway/config
set \$mod Mod4
set \$term foot
set \$menu wofi --show drun --allow-images

# Cores Ubuntu
client.focused #E95420 #E95420 #ffffff #E95420
output * bg /usr/share/backgrounds/warty-final-ubuntu.png fill

# Atalhos Básicos
bindsym \$mod+Return exec \$term
bindsym \$mod+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair?' -b 'Sim' 'swaymsg exit'
bindsym \$mod+h exec bash ~/sway/help_atalhos.sh

# Barra
bar {
    swaybar_command waybar
}

# Teclado
input "type:keyboard" {
    xkb_layout br
}

# Mouse
input "type:pointer" {
    accel_profile "flat"
    pointer_accel -0.2
    tap enabled
    natural_scroll disable
    scroll_factor 1.0
}

# Background Apps
exec nm-applet --indicator
exec dunst

# Sessões e Divisões
bindsym \$mod+v splitv
bindsym \$mod+b splith
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2
bindsym \$mod+3 workspace number 3
bindsym \$mod+4 workspace number 4
bindsym \$mod+5 workspace number 5

bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4
bindsym \$mod+Shift+5 move container to workspace number 5

# Layouts
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

# Controle de Volume
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Bordas e Gaps
gaps inner 8
gaps outer 2
smart_borders on
EOF

# 4. Gerando ~/.config/waybar/config
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
    "memory": { "format": "🎟 {}%" }
}
EOF

# 5. Gerando ~/.config/waybar/style.css
cat <<EOF > ~/.config/waybar/style.css
* {
    font-family: "Ubuntu", "Font Awesome 6 Free", sans-serif;
    font-size: 14px;
}
window#waybar {
    background-color: rgba(48, 10, 36, 0.95);
    border-bottom: 2px solid #E95420;
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

# 6. Atualizando .bashrc
grep -qq "XDG_CURRENT_DESKTOP=sway" ~/.bashrc || echo 'export XDG_CURRENT_DESKTOP=sway' >> ~/.bashrc
grep -qq "MOZ_ENABLE_WAYLAND=1" ~/.bashrc || echo 'export MOZ_ENABLE_WAYLAND=1' >> ~/.bashrc

echo "✅ Script install.sh atualizado e pronto para uso!"

# --- FIM DO CÓDIGO MODIFICADO ---
