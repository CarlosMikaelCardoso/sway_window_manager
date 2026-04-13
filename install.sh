# --- INÍCIO DO CÓDIGO MODIFICADO (Sway Config atualizado com Mouse e Áudio) ---

cat <<EOF > ~/.config/sway/config
# Tecla Principal: Windows
set \$mod Mod4
set \$term foot
set \$menu wofi --show drun --allow-images

# Cores Temáticas Ubuntu
client.focused #E95420 #E95420 #ffffff #E95420
output * bg /usr/share/backgrounds/warty-final-ubuntu.png fill

# Atalhos de Teclado
bindsym \$mod+Return exec \$term
bindsym \$mod+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair do Sway?' -b 'Sim' 'swaymsg exit'
bindsym \$mod+h exec bash ~/help_atalhos.sh

# --- NOVO: Gestão de Sessões (Workspaces) ---
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2
bindsym \$mod+3 workspace number 3
bindsym \$mod+4 workspace number 4
bindsym \$mod+5 workspace number 5

# Mover janelas entre sessões
bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4
bindsym \$mod+Shift+5 move container to workspace number 5

# --- NOVO: Correção das Teclas de Volume (Fn) ---
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Barra de Status
bar {
    swaybar_command waybar
}

# Configuração de Teclado (BR ABNT2)
input "type:keyboard" {
    xkb_layout br
}

# --- NOVO: Ajuste de Sensibilidade do Mouse ---
input "type:pointer" {
    accel_profile "flat"
    pointer_accel -0.2
}

# Iniciar Apps em Background
exec nm-applet --indicator
exec_always waybar

# Gaps e Bordas (Estilo Moderno)
gaps inner 8
gaps outer 2
smart_borders on
EOF

# --- FIM DO CÓDIGO MODIFICADO ---
