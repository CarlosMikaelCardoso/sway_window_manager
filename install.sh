#!/bin/bash

# --- INÍCIO DO SCRIPT DE INSTALAÇÃO COMPLETA SWAY ---

echo "🚀 Iniciando a transformação completa para Sway (Wayland)..."

# 1. Instalação de todos os pacotes necessários
echo "📦 Instalando pacotes..."
sudo apt update
sudo apt install -y sway waybar wofi swaybg swayidle swaylock foot wlogout \
    fonts-font-awesome fonts-noto-color-emoji fonts-liberation \
    grim slurp pavucontrol blueman wdisplays network-manager-gnome \
    zenity pulseaudio-utils

# 2. Criação dos diretórios de configuração
mkdir -p ~/.config/sway ~/.config/waybar ~/.config/foot

# 3. Gerando o arquivo de configuração do SWAY
echo "📝 Configurando o Sway..."
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

# Teclas Multimídia
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

# Iniciar Apps em Background
exec nm-applet --indicator
exec_always waybar

# Gaps e Bordas (Estilo Moderno)
gaps inner 8
gaps outer 2
smart_borders on
EOF

# 4. Gerando a configuração da Waybar (Barra Superior)
echo "📊 Configurando a Waybar..."
cat <<EOF > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "cpu", "memory", "tray"],
    "clock": { "format": "{:%d/%m/%Y - %H:%M}" },
    "pulseaudio": { "format": "{icon} {volume}%", "format-icons": {"default": ["", "", ""]} },
    "cpu": { "format": " {usage}%" },
    "memory": { "format": " {}%" }
}
EOF

# CSS da Waybar (Cores Ubuntu)
cat <<EOF > ~/.config/waybar/style.css
window#waybar { background: rgba(48, 10, 36, 0.95); border-bottom: 2px solid #E95420; color: white; }
#workspaces button.focused { background: #E95420; }
#clock, #pulseaudio, #cpu, #memory { padding: 0 10px; }
EOF

# 5. Criando o Script de Ajuda (Super+H)
echo "❓ Criando guia de atalhos..."
cat <<EOF > ~/help_atalhos.sh
#!/bin/bash
TEXTO="<b>ATALHOS SWAY:</b>\n\n• <b>Super + Enter</b>: Terminal\n• <b>Super + D</b>: Menu Apps\n• <b>Super + Q</b>: Fechar Janela\n• <b>Super + H</b>: Este Guia\n\n<b>CONFIGS:</b>\n• <b>nmtui</b>: Wi-Fi\n• <b>pavucontrol</b>: Som"
zenity --info --title="Ajuda" --text="\$TEXTO" --width=300
EOF
chmod +x ~/help_atalhos.sh

# 6. Variáveis de Ambiente no .bashrc
grep -qq "XDG_CURRENT_DESKTOP=sway" ~/.bashrc || echo 'export XDG_CURRENT_DESKTOP=sway' >> ~/.bashrc
grep -qq "MOZ_ENABLE_WAYLAND=1" ~/.bashrc || echo 'export MOZ_ENABLE_WAYLAND=1' >> ~/.bashrc

echo "✅ Instalação concluída! Reinicie a sessão e entre no Sway."

# --- FIM DO SCRIPT DE INSTALAÇÃO COMPLETA SWAY ---
