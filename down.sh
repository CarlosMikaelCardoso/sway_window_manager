#!/bin/bash

echo "🔄 Resetando configurações e removendo conflitos..."

# 1. Limpeza Total (Remove as pastas que o repositório criou)
rm -rf ~/.config/sway
rm -rf ~/.config/waybar
rm -rf ~/.config/foot
rm -rf ~/.config/rofi
rm -rf ~/.config/kitty

# 2. Recriar estrutura limpa
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/.config/foot

# 3. Gerar o arquivo CONFIG principal (Sem conflitos)
cat <<EOF > ~/.config/sway/config
# --- CONFIGURAÇÃO LIMPA E SEM CONFLITOS ---

# Teclas e Apps Padrão
set \$mod Mod4
set \$term foot
set \$menu wofi --show drun --allow-images

# Visual
output * bg /usr/share/backgrounds/warty-final-ubuntu.png fill
client.focused #E95420 #E95420 #ffffff #E95420
gaps inner 8
gaps outer 2

# --- ATALHOS BÁSICOS ---
bindsym \$mod+Return exec \$term
bindsym \$mod+d exec \$menu
bindsym \$mod+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair?' -b 'Sim' 'swaymsg exit'
bindsym \$mod+h exec bash ~/help_atalhos.sh

# --- WORKSPACES (Sessões) ---
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

# --- HARDWARE (Teclado, Mouse e Som) ---
input "type:keyboard" {
    xkb_layout br
}

input "type:pointer" {
    accel_profile flat
    pointer_accel -0.2
}

bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# --- INICIALIZAÇÃO ---
exec nm-applet --indicator
bar {
    swaybar_command waybar
}
EOF

# 4. Gerar Waybar Simples (Estilo Ubuntu)
cat <<EOF > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "tray"],
    "clock": { "format": "{:%H:%M}" }
}
EOF

cat <<EOF > ~/.config/waybar/style.css
window#waybar { background: #300A24; border-bottom: 2px solid #E95420; color: white; }
#workspaces button.focused { background: #E95420; }
#clock, #pulseaudio, #cpu, #memory { padding: 0 10px; }
EOF

echo "✅ Reset concluído! Use Super+Shift+C ou reinicie a sessão."
