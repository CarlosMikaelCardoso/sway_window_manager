#!/bin/bash
# Popup de controles MPD em estilo dock (macOS / Control Center)

set -euo pipefail

SINGLE_INSTANCE=false
for arg in "$@"; do
    case "$arg" in
        --single-instance)
            SINGLE_INSTANCE=true
            ;;
    esac
done

LOCK_FILE="/tmp/mpd_dock_popup.lock"
if [ "$SINGLE_INSTANCE" = true ]; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        exit 0
    fi
fi

if ! command -v mpc >/dev/null 2>&1; then
    notify-send "MPD" "mpc nao encontrado" >/dev/null 2>&1 || true
    exit 1
fi

if ! command -v yad >/dev/null 2>&1; then
    notify-send "MPD" "yad nao encontrado. Instale com: sudo apt install yad" >/dev/null 2>&1 || true
    exit 1
fi

systemctl --user start mpd >/dev/null 2>&1 || true

# Modificação: Substituição do YAD por uma interface nativa GTK3 em Python.
# Cria uma janela com timeline interativa (slider) mantendo a aparência de extensão da Waybar.

# Garante que as dependências do GTK para Python estejam instaladas
if ! dpkg -s python3-gi gir1.2-gtk-3.0 >/dev/null 2>&1; then
    notify-send "MPD" "Instalando dependências GTK..." >/dev/null 2>&1 || true
    sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y python3-gi gir1.2-gtk-3.0 >/dev/null 2>&1
fi

WIN_WIDTH=520
WIN_HEIGHT=380
POS_X=0
POS_Y=32

if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    OUTPUT_RECT_JSON="$(swaymsg -t get_outputs | jq -c '.[] | select(.focused) | .rect' | head -n1)"
    if [ -n "${OUTPUT_RECT_JSON:-}" ] && [ "$OUTPUT_RECT_JSON" != "null" ]; then
        OUT_X="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.x')"
        OUT_Y="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.y')"
        OUT_W="$(printf '%s' "$OUTPUT_RECT_JSON" | jq -r '.width')"
        POS_X=$(( OUT_X + (OUT_W - WIN_WIDTH) / 2 ))
        POS_Y=$(( OUT_Y - 10))
    fi
fi

PYTHON_SCRIPT="/tmp/mpd_dock_gtk.py"
cat > "$PYTHON_SCRIPT" <<'EOF'
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk
import subprocess
import re

class MPDDock(Gtk.Window):
    def __init__(self):
        super().__init__(title="MPD Dock")
        self.set_default_size(520, 230)
        self.set_decorated(False)
        self.set_border_width(15)
        # Identificador para o Sway reconhecer a janela
        self.set_wmclass("mpd-popup", "mpd-popup")
        
        # Estilo integrado com a Waybar
        css = b"""
        window {
            background-color: rgba(30, 30, 30, 0.85);
            border-radius: 0 0 20px 20px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-top: none;
        }
        label { color: #ffffff; font-family: "Ubuntu", sans-serif; }
        .title { font-size: 20px; font-weight: bold; margin-top: 5px; }
        .artist { font-size: 14px; color: #a1a1a6; margin-bottom: 10px; }
        .time { font-size: 12px; color: #888888; }
        scale trough { min-height: 4px; border-radius: 2px; background-color: rgba(255,255,255,0.2); }
        scale highlight { background-color: #ffffff; border-radius: 2px; }
        scale slider { min-width: 14px; min-height: 14px; border-radius: 7px; background-color: #ffffff; margin: -5px; }
        button { background-color: rgba(255, 255, 255, 0.12); border-radius: 12px; border: none; padding: 10px 15px; font-size: 18px; color: white; margin: 0 4px; }
        button:hover { background-color: rgba(255, 255, 255, 0.25); }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        self.add(vbox)
        
        self.lbl_title = Gtk.Label(label="Carregando...")
        self.lbl_title.get_style_context().add_class("title")
        vbox.pack_start(self.lbl_title, False, False, 0)
        
        self.lbl_artist = Gtk.Label(label="")
        self.lbl_artist.get_style_context().add_class("artist")
        vbox.pack_start(self.lbl_artist, False, False, 0)
        
        # Timeline
        hbox_time = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        hbox_time.set_margin_start(10)
        hbox_time.set_margin_end(10)
        
        self.lbl_time_cur = Gtk.Label(label="0:00")
        self.lbl_time_cur.get_style_context().add_class("time")
        self.lbl_time_tot = Gtk.Label(label="0:00")
        self.lbl_time_tot.get_style_context().add_class("time")
        
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale.set_draw_value(False)
        self.scale.connect("button-release-event", self.on_seek)
        self.scale.connect("button-press-event", self.on_seek_press)
        self.is_seeking = False
        
        hbox_time.pack_start(self.lbl_time_cur, False, False, 0)
        hbox_time.pack_start(self.scale, True, True, 0)
        hbox_time.pack_start(self.lbl_time_tot, False, False, 0)
        vbox.pack_start(hbox_time, False, False, 10)
        
        # Botões
        hbox_btn = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        hbox_btn.set_halign(Gtk.Align.CENTER)
        
        btn_close = Gtk.Button(label="✕")
        btn_close.connect("clicked", lambda x: Gtk.main_quit())

        btn_prev = Gtk.Button(label="")
        btn_prev.connect("clicked", lambda x: self.cmd("mpc prev"))
        
        btn_bwd = Gtk.Button(label="")
        btn_bwd.connect("clicked", lambda x: self.cmd("mpc seek -10"))
        
        self.btn_play = Gtk.Button(label="")
        self.btn_play.connect("clicked", lambda x: self.cmd("mpc toggle"))
        
        btn_fwd = Gtk.Button(label="")
        btn_fwd.connect("clicked", lambda x: self.cmd("mpc seek +10"))
        
        btn_next = Gtk.Button(label="")
        btn_next.connect("clicked", lambda x: self.cmd("mpc next"))

        btn_app = Gtk.Button(label="")
        btn_app.connect("clicked", lambda x: [self.cmd("foot -e ncmpcpp &"), Gtk.main_quit()])
        
        for b in [btn_close, btn_prev, btn_bwd, self.btn_play, btn_fwd, btn_next, btn_app]:
            hbox_btn.pack_start(b, False, False, 0)
            
        vbox.pack_start(hbox_btn, False, False, 10)
        
        self.update_status()
        GLib.timeout_add_seconds(1, self.update_status)
        
    def cmd(self, command):
        subprocess.run(command, shell=True)
        self.update_status()
        subprocess.run("pkill -RTMIN+10 waybar", shell=True)
        
    def on_seek_press(self, widget, event):
        self.is_seeking = True
        
    def on_seek(self, widget, event):
        val = self.scale.get_value()
        subprocess.run(f"mpc seek {int(val)}%", shell=True)
        self.is_seeking = False
        self.update_status()
        
    def update_status(self):
        if self.is_seeking: return True
        try:
            import os
            status = subprocess.check_output("mpc status", shell=True, text=True).split('\n')
            # Busca Título, Artista e o caminho do Arquivo para processamento
            raw_info = subprocess.check_output('mpc current -f "%title%\n%artist%\n%file%"', shell=True, text=True).split('\n')
            
            title = raw_info[0] if len(raw_info) > 0 else ""
            artist = raw_info[1] if len(raw_info) > 1 else ""
            filename = raw_info[2] if len(raw_info) > 2 else ""

            # Modificação: Reimplementação da lógica de tratamento de título original
            if not title and filename:
                title = os.path.basename(filename)
                title = os.path.splitext(title)[0] # Remove extensão
                if ". " in title:
                    title = title.split(". ", 1)[1] # Remove prefixo "01. "
                title = re.sub(r'-[A-Za-z0-9_-]{8,}$', '', title) # Remove sufixo de ID (ex: YouTube)
            
            if not artist:
                artist = ""
            
            if not title or title == "Nenhuma Mídia":
                title = "Nenhuma Mídia"
                artist = "MPD Parado"

            self.lbl_title.set_text(title[:40] + ("..." if len(title) > 40 else ""))
            self.lbl_artist.set_text(artist[:40] + ("..." if len(artist) > 40 else ""))
            
            if len(status) > 1 and '[' in status[1]:
                state_line = status[1]
                self.btn_play.set_label("" if "[playing]" in state_line else "")
                
                time_match = re.search(r'(\d+:\d+)/(\d+:\d+)', state_line)
                pct_match = re.search(r'\((\d+)%\)', state_line)
                
                if time_match and pct_match:
                    self.lbl_time_cur.set_text(time_match.group(1))
                    self.lbl_time_tot.set_text(time_match.group(2))
                    self.scale.set_value(float(pct_match.group(1)))
        except Exception:
            pass
        return True

win = MPDDock()
win.show_all()
Gtk.main()
EOF

# Executa a interface GTK em background
python3 "$PYTHON_SCRIPT" &
APP_PID=$!

if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    # Reposiciona o app logo que ele abre para não quebrar as janelas atuais no fundo
    for _ in $(seq 1 20); do
        WIN_ID="$(swaymsg -t get_tree | jq -r --argjson pid "$APP_PID" '
          .. | objects
          | select(.pid? == $pid and .name? == "MPD Dock")
          | .id
        ' | head -n1)"

        if [ -n "${WIN_ID:-}" ] && [ "$WIN_ID" != "null" ]; then
            swaymsg "[con_id=$WIN_ID] floating enable, sticky enable, border none, move position $POS_X $POS_Y" >/dev/null 2>&1 || true
            break
        fi
        sleep 0.03
    done
fi

wait "$APP_PID"