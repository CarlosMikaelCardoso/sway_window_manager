#!/bin/bash

# --- INSTALAÇÃO BASE DO SWAY ---

echo "🛠️ Instalando base do Sway..."

# 1. Instala apenas o núcleo do ambiente Sway
sudo apt update
sudo apt install -y sway swaybg swayidle swaylock foot dbus-x11 xdg-desktop-portal-wlr

# 2. Criar estrutura básica de configuração
mkdir -p ~/.config/sway ~/.config/foot

# 3. Gerar config mínima do Sway (sem tema/customização)
cat <<EOF > ~/.config/sway/config
set \$mod Mod4
set \$term foot

exec dbus-update-activation-environment --all

bindsym \$mod+Return exec \$term
bindsym \$mod+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair?' -b 'Sim' 'swaymsg exit'

input "type:keyboard" {
    xkb_layout br
}

floating_modifier \$mod
EOF

echo "✅ Instalação base concluída."
echo "➡️ Agora rode: ./customiza.sh"
