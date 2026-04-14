#!/bin/bash

# --- CUSTOMIZAÇÃO: EXTRAS + TEMA ---

echo "🎨 Instalando extras e aplicando tema do Sway/Waybar..."

# 1. Instalar dependências extras (barra, launcher, rede, áudio, etc.)
sudo apt update
sudo apt install -y waybar wofi \
    fonts-font-awesome fonts-noto-color-emoji fonts-liberation \
    grim slurp pavucontrol blueman wdisplays network-manager-gnome \
    zenity yad pulseaudio-utils dunst jq playerctl mpd mpc ncmpcpp

# 2. Criar pastas de config
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/sway/components/sway ~/sway/components/waybar

# 2.1 Configurar MPD (biblioteca local de músicas)
MUSIC_DIR=""
for CANDIDATE in "$HOME/Musicas" "$HOME/Música" "$HOME/Músicas" "$HOME/Music"; do
    if [ -d "$CANDIDATE" ]; then
        MUSIC_DIR="$CANDIDATE"
        break
    fi
done

if [ -z "$MUSIC_DIR" ]; then
    MUSIC_DIR="$HOME/Musicas"
    mkdir -p "$MUSIC_DIR"
fi

mkdir -p ~/.config/mpd/playlists ~/.config/mpd

cat <<EOF > ~/.config/mpd/mpd.conf
music_directory "$MUSIC_DIR"
playlist_directory "~/.config/mpd/playlists"
db_file "~/.config/mpd/database"
log_file "~/.config/mpd/log"
pid_file "~/.config/mpd/pid"
state_file "~/.config/mpd/state"
sticker_file "~/.config/mpd/sticker.sql"
bind_to_address "127.0.0.1"
port "6600"
auto_update "yes"
restore_paused "yes"

audio_output {
    type "pipewire"
    name "PipeWire Sound Server"
}
EOF

systemctl --user enable --now mpd >/dev/null 2>&1 || true
mpc update >/dev/null 2>&1 || true

# 3. Gerar configuração da Waybar (dock flutuante)
cat <<EOF > ~/.config/waybar/config
{
    "layer": "top",
    "exclusive": false,
    "position": "top",
    "margin-top": 6,
    "margin-left": 18,
    "margin-right": 18,
    "height": 24,
    "on-sigusr1": "toggle",
    "modules-left": ["sway/workspaces", "sway/mode", "custom/win-hide", "custom/win-max", "custom/win-close"],
    "modules-center": ["custom/clock", "custom/media"],
    "modules-right": ["custom/audio", "custom/cpu", "custom/memory", "tray"],
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
    },
    "custom/media": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/media_mpd.sh",
        "on-click": "bash ~/sway/components/sway/mpd_dock_popup.sh --single-instance",
        "on-click-right": "foot -e ncmpcpp",
        "on-scroll-up": "mpc next >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true",
        "on-scroll-down": "mpc prev >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true",
        "signal": 10,
        "interval": 2,
        "tooltip": true
    },
    "custom/clock": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/clock.sh",
        "interval": 1,
        "tooltip": true
    },
    "custom/audio": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/audio.sh",
        "on-click": "bash ~/sway/components/sway/volume_control.sh mute",
        "signal": 9,
        "interval": 10,
        "tooltip": true
    },
    "custom/win-hide": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/window_controls.sh status hide",
        "on-click": "bash ~/sway/components/waybar/window_controls.sh action hide",
        "interval": 1
    },
    "custom/win-max": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/window_controls.sh status max",
        "on-click": "bash ~/sway/components/waybar/window_controls.sh action max",
        "interval": 1
    },
    "custom/win-close": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/window_controls.sh status close",
        "on-click": "bash ~/sway/components/waybar/window_controls.sh action close",
        "interval": 1
    },
    "custom/cpu": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/cpu.sh",
        "interval": 2,
        "tooltip": true
    },
    "custom/memory": {
        "return-type": "json",
        "exec": "bash ~/sway/components/waybar/memory.sh",
        "interval": 2,
        "tooltip": true
    }
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
#custom-clock,
#custom-audio,
#custom-cpu,
#custom-memory,
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

#custom-media {
    background-color: #66cc99;
    color: #2b273f;
    border-radius: 4px;
    padding: 0 10px;
    margin: 0 5px;
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
#custom-audio { color: #cdb4db; }
#custom-cpu { color: #a3be8c; }
#custom-memory { color: #f2cc8f; }
#custom-clock { color: #bde0fe; }

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

# Ambiente de sessão para D-Bus e portais (evita falha de start da Waybar)
exec_always --no-startup-id dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway
exec_always --no-startup-id systemctl --user restart xdg-desktop-portal xdg-desktop-portal-wlr

# Atalhos
bindsym \$mod+Return exec \$term
bindsym \$mod+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Sair?' -b 'Sim' 'swaymsg exit'
bindsym \$mod+h exec bash ~/sway/components/sway/help_atalhos.sh
bindsym \$mod+Ctrl+b exec pkill -USR1 waybar
bindsym \$mod+a exec bash ~/sway/components/sway/janela_acoes.sh

# Navegação de janelas (workspace atual)
bindsym Mod1+Tab exec bash ~/sway/components/sway/alt_tab_visual.sh next 300
bindsym Mod1+Shift+Tab exec bash ~/sway/components/sway/alt_tab_visual.sh prev 300
bindsym Mod1+ISO_Left_Tab exec bash ~/sway/components/sway/alt_tab_visual.sh prev 300
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

# Volume (teclas multimidia/FN)
bindsym XF86AudioRaiseVolume exec bash ~/sway/components/sway/volume_control.sh up
bindsym XF86AudioLowerVolume exec bash ~/sway/components/sway/volume_control.sh down
bindsym XF86AudioMute exec bash ~/sway/components/sway/volume_control.sh mute

# Mídia (MPD)
bindsym XF86AudioPlay exec sh -c 'mpc toggle >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true'
bindsym XF86AudioNext exec sh -c 'mpc next >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true'
bindsym XF86AudioPrev exec sh -c 'mpc prev >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true'
bindsym XF86AudioStop exec sh -c 'mpc stop >/dev/null 2>&1; pkill -RTMIN+10 waybar >/dev/null 2>&1 || true'
bindsym \$mod+m exec foot -e ncmpcpp
bindsym \$mod+Shift+m exec bash ~/sway/components/sway/mpd_dock_popup.sh --single-instance

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

# Iniciar Barra automaticamente (nativo do Sway)
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
    pointer_accel 0
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

# 6. Scripts de componentes do Sway
copy_component() {
    local src="$1"
    local dst="$2"

    if [ -f "$src" ]; then
        local src_abs dst_abs
        src_abs="$(readlink -f "$src")"
        dst_abs="$(readlink -f "$dst" 2>/dev/null || echo "$dst")"
        if [ "$src_abs" != "$dst_abs" ]; then
            cp "$src_abs" "$dst"
        fi
        chmod +x "$dst"
    else
        echo "⚠️ Componente não encontrado: $src"
    fi
}

copy_component "$(dirname "$0")/components/sway/help_atalhos.sh" "$HOME/sway/components/sway/help_atalhos.sh"
copy_component "$(dirname "$0")/components/sway/alt_tab_visual.sh" "$HOME/sway/components/sway/alt_tab_visual.sh"
copy_component "$(dirname "$0")/components/sway/janela_acoes.sh" "$HOME/sway/components/sway/janela_acoes.sh"
copy_component "$(dirname "$0")/components/sway/volume_control.sh" "$HOME/sway/components/sway/volume_control.sh"
copy_component "$(dirname "$0")/components/sway/mpd_picker.sh" "$HOME/sway/components/sway/mpd_picker.sh"
copy_component "$(dirname "$0")/components/sway/mpd_menu.sh" "$HOME/sway/components/sway/mpd_menu.sh"
copy_component "$(dirname "$0")/components/sway/mpd_dock_popup.sh" "$HOME/sway/components/sway/mpd_dock_popup.sh"

# 7. Scripts de componentes da Waybar
copy_component "$(dirname "$0")/components/waybar/window_controls.sh" "$HOME/sway/components/waybar/window_controls.sh"
copy_component "$(dirname "$0")/components/waybar/net_speed.sh" "$HOME/sway/components/waybar/net_speed.sh"
copy_component "$(dirname "$0")/components/waybar/clock.sh" "$HOME/sway/components/waybar/clock.sh"
copy_component "$(dirname "$0")/components/waybar/audio.sh" "$HOME/sway/components/waybar/audio.sh"
copy_component "$(dirname "$0")/components/waybar/media_mpd.sh" "$HOME/sway/components/waybar/media_mpd.sh"
copy_component "$(dirname "$0")/components/waybar/cpu.sh" "$HOME/sway/components/waybar/cpu.sh"
copy_component "$(dirname "$0")/components/waybar/memory.sh" "$HOME/sway/components/waybar/memory.sh"

# Remove script legado de startup para evitar confusão
rm -f ~/sway/start_waybar.sh

# 8. Correções do VS Code (clipboard/atalhos no Wayland)
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
