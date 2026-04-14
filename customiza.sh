#!/bin/bash

# --- CUSTOMIZAÇÃO: EXTRAS + TEMA ---

echo "🎨 Instalando extras e aplicando tema do Sway/Waybar..."

# 1. Instalar dependências extras (barra, launcher, rede, áudio, etc.)
sudo apt update
sudo apt install -y waybar wofi \
    fonts-font-awesome fonts-noto-color-emoji fonts-liberation \
    grim slurp pavucontrol blueman wdisplays network-manager-gnome \
    zenity pulseaudio-utils dunst jq

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
    "modules-left": ["sway/workspaces", "sway/mode", "custom/win-hide", "custom/win-max", "custom/win-close"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "cpu", "memory", "tray"],
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
    "custom/win-hide": {
        "return-type": "json",
        "exec": "bash ~/sway/waybar_window_controls.sh status hide",
        "on-click": "bash ~/sway/waybar_window_controls.sh action hide",
        "interval": 1
    },
    "custom/win-max": {
        "return-type": "json",
        "exec": "bash ~/sway/waybar_window_controls.sh status max",
        "on-click": "bash ~/sway/waybar_window_controls.sh action max",
        "interval": 1
    },
    "custom/win-close": {
        "return-type": "json",
        "exec": "bash ~/sway/waybar_window_controls.sh status close",
        "on-click": "bash ~/sway/waybar_window_controls.sh action close",
        "interval": 1
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
#cpu,
#memory,
#custom-win-hide,
#custom-win-max,
#custom-win-close,
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

#custom-win-hide,
#custom-win-max,
#custom-win-close {
    font-weight: bold;
    min-width: 18px;
}

#custom-win-hide { color: #f6d365; }
#custom-win-max { color: #8dd694; }
#custom-win-close { color: #ff6b6b; }
#custom-net-speed { color: #8ecae6; }

#custom-win-hide.hidden,
#custom-win-max.hidden,
#custom-win-close.hidden {
    background-color: transparent;
    border: 0;
    margin: 0;
    padding: 0;
    min-width: 0;
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
bindsym \$mod+a exec bash ~/sway/janela_acoes.sh

# Navegação de janelas (workspace atual)
bindsym Mod1+Tab exec bash ~/sway/alt_tab_visual.sh next 300
bindsym Mod1+Shift+Tab exec bash ~/sway/alt_tab_visual.sh prev 300
bindsym Mod1+ISO_Left_Tab exec bash ~/sway/alt_tab_visual.sh prev 300
bindsym \$mod+Left focus left
bindsym \$mod+Right focus right
bindsym \$mod+Up focus up
bindsym \$mod+Down focus down
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Right move right
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Down move down

# Ações de janela (estilo produtividade)
bindsym \$mod+Shift+space floating toggle
bindsym \$mod+f fullscreen toggle
bindsym \$mod+minus move scratchpad
bindsym \$mod+equal scratchpad show

# Prints de tela
bindsym Print exec mkdir -p ~/Imagens/prints && grim ~/Imagens/prints/print-\$(date +%Y-%m-%d_%H-%M-%S).png
bindsym Shift+Print exec mkdir -p ~/Imagens/prints && grim -g "\$(slurp)" ~/Imagens/prints/print-area-\$(date +%Y-%m-%d_%H-%M-%S).png
bindsym Ctrl+Print exec sh -c 'sleep 3; mkdir -p ~/Imagens/prints; grim ~/Imagens/prints/print-delay-\$(date +%Y-%m-%d_%H-%M-%S).png'

# Workspaces
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

# Iniciar Barra automaticamente
bar {
    swaybar_command waybar
}

# Teclado e Mouse
input "type:keyboard" {
    xkb_layout br
}

floating_modifier \$mod normal
focus_follows_mouse yes
focus_on_window_activation focus

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
    SRC_HELP="$(readlink -f "$(dirname "$0")/help_atalhos.sh")"
    DST_HELP="$(readlink -f ~/sway/help_atalhos.sh 2>/dev/null || echo ~/sway/help_atalhos.sh)"
    if [ "$SRC_HELP" != "$DST_HELP" ]; then
        cp "$SRC_HELP" ~/sway/help_atalhos.sh
    fi
else
    echo "⚠️ help_atalhos.sh não encontrado no repositório. Mantendo configuração atual."
fi
chmod +x ~/sway/help_atalhos.sh

# 7. Script de Alt+Tab visual (fonte única: arquivo do repositório)
if [ -f "$(dirname "$0")/alt_tab_visual.sh" ]; then
    SRC_ALT="$(readlink -f "$(dirname "$0")/alt_tab_visual.sh")"
    DST_ALT="$(readlink -f ~/sway/alt_tab_visual.sh 2>/dev/null || echo ~/sway/alt_tab_visual.sh)"
    if [ "$SRC_ALT" != "$DST_ALT" ]; then
        cp "$SRC_ALT" ~/sway/alt_tab_visual.sh
    fi
else
    echo "⚠️ alt_tab_visual.sh não encontrado no repositório. Alt+Tab visual pode não funcionar."
fi
chmod +x ~/sway/alt_tab_visual.sh

# 8. Script de ações de janela (fonte única: arquivo do repositório)
if [ -f "$(dirname "$0")/janela_acoes.sh" ]; then
    SRC_WIN="$(readlink -f "$(dirname "$0")/janela_acoes.sh")"
    DST_WIN="$(readlink -f ~/sway/janela_acoes.sh 2>/dev/null || echo ~/sway/janela_acoes.sh)"
    if [ "$SRC_WIN" != "$DST_WIN" ]; then
        cp "$SRC_WIN" ~/sway/janela_acoes.sh
    fi
else
    echo "⚠️ janela_acoes.sh não encontrado no repositório. Menu de ações pode não funcionar."
fi
chmod +x ~/sway/janela_acoes.sh

# 9. Script dos cards de controle de janela na Waybar
if [ -f "$(dirname "$0")/waybar_window_controls.sh" ]; then
    SRC_CTRL="$(readlink -f "$(dirname "$0")/waybar_window_controls.sh")"
    DST_CTRL="$(readlink -f ~/sway/waybar_window_controls.sh 2>/dev/null || echo ~/sway/waybar_window_controls.sh)"
    if [ "$SRC_CTRL" != "$DST_CTRL" ]; then
        cp "$SRC_CTRL" ~/sway/waybar_window_controls.sh
    fi
else
    echo "⚠️ waybar_window_controls.sh não encontrado no repositório. Cards de janela podem não funcionar."
fi
chmod +x ~/sway/waybar_window_controls.sh

# 10. Script de velocidade de rede na Waybar
if [ -f "$(dirname "$0")/waybar_net_speed.sh" ]; then
    SRC_NET="$(readlink -f "$(dirname "$0")/waybar_net_speed.sh")"
    DST_NET="$(readlink -f ~/sway/waybar_net_speed.sh 2>/dev/null || echo ~/sway/waybar_net_speed.sh)"
    if [ "$SRC_NET" != "$DST_NET" ]; then
        cp "$SRC_NET" ~/sway/waybar_net_speed.sh
    fi
else
    echo "⚠️ waybar_net_speed.sh não encontrado no repositório. Módulo de velocidade pode não funcionar."
fi
chmod +x ~/sway/waybar_net_speed.sh

# 11. Correções do VS Code (clipboard/atalhos no Wayland)
mkdir -p ~/.config/Code/User ~/.local/share/applications

cat <<EOF > ~/.config/Code/User/keybindings.json
[
    {
        "key": "ctrl+c",
        "command": "editor.action.clipboardCopyAction",
        "when": "editorTextFocus && !editorReadonly"
    },
    {
        "key": "ctrl+x",
        "command": "editor.action.clipboardCutAction",
        "when": "editorTextFocus && !editorReadonly"
    },
    {
        "key": "ctrl+v",
        "command": "editor.action.clipboardPasteAction",
        "when": "editorTextFocus && !editorReadonly"
    },
    {
        "key": "ctrl+c",
        "command": "workbench.action.terminal.copySelection",
        "when": "terminalFocus && terminalTextSelected"
    },
    {
        "key": "ctrl+shift+v",
        "command": "workbench.action.terminal.paste",
        "when": "terminalFocus"
    }
]
EOF

# Launcher em Wayland para evitar problemas de teclado/clipboard no Sway
if [ -x /snap/bin/code ]; then
    cat <<EOF > ~/.local/share/applications/code-wayland.desktop
[Desktop Entry]
Name=Visual Studio Code (Wayland)
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/snap/bin/code --ozone-platform=wayland %F
Icon=code
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;
EOF
fi

echo "✅ Customização aplicada!"
echo "➡️ Use Super+Shift+C para recarregar no Sway (ou reinicie a sessão)."

# --- FIM DO SCRIPT ---
