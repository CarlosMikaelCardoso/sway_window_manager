#!/bin/bash

# Controle de ações de janela para módulos custom da Waybar
# Uso:
#   window_controls.sh status <hide|max|close>
#   window_controls.sh action <hide|max|close>

set -euo pipefail

MODE="${1:-status}"
KIND="${2:-hide}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway-waybar"
AUTOHIDE_MARK="$STATE_DIR/autohide_by_max"

if ! command -v swaymsg >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

get_focused_window_id() {
    swaymsg -t get_tree | jq -r '
      .. | objects
      | select(.focused? == true and (.type? == "con" or .type? == "floating_con"))
      | .id
    ' | head -n1
}

get_focused_fullscreen_mode() {
    swaymsg -t get_tree | jq -r '
      .. | objects
      | select(.focused? == true and (.type? == "con" or .type? == "floating_con"))
      | (.fullscreen_mode // 0)
    ' | head -n1
}

has_window_in_focused_workspace() {
    local ws
    ws="$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name' | head -n1)"
    [ -n "$ws" ] || return 1

    local count
    count="$(swaymsg -t get_tree | jq -r --arg ws "$ws" '
      [
        .. | objects
        | select(.type? == "workspace" and .name? == $ws)
        | .. | objects
        | select((.type? == "con" or .type? == "floating_con") and (.app_id? != null or .window_properties? != null))
      ] | length
    ')"

    [ "${count:-0}" -gt 0 ]
}

status_output() {
    if ! has_window_in_focused_workspace; then
        echo '{"text":"","class":"hidden"}'
        return
    fi

    case "$KIND" in
        close)
            echo '{"text":"●","tooltip":"Fechar janela atual"}'
            ;;
        hide)
            echo '{"text":"●","tooltip":"Esconder janela atual"}'
            ;;
        max)
            echo '{"text":"●","tooltip":"Maximizar/Restaurar janela atual"}'
            ;;
        *)
            echo '{"text":"","class":"hidden"}'
            ;;
    esac
}

action_exec() {
    local id
    id="$(get_focused_window_id)"
    [ -n "$id" ] || exit 0

    case "$KIND" in
        hide)
            swaymsg "[con_id=$id] move scratchpad" >/dev/null
            ;;
        max)
            mkdir -p "$STATE_DIR"

            # fullscreen_mode: 0 = normal, 1/2 = fullscreen
            local current_mode
            current_mode="$(get_focused_fullscreen_mode)"

            swaymsg "[con_id=$id] fullscreen toggle" >/dev/null

            if [ "${current_mode:-0}" -eq 0 ]; then
                # Entrou em fullscreen: oculta a Waybar e marca que foi este script.
                pkill -USR1 waybar >/dev/null 2>&1 || true
                : > "$AUTOHIDE_MARK"
            else
                # Saiu de fullscreen: restaura a Waybar apenas se este script escondeu.
                if [ -f "$AUTOHIDE_MARK" ]; then
                    pkill -USR1 waybar >/dev/null 2>&1 || true
                    rm -f "$AUTOHIDE_MARK"
                fi
            fi
            ;;
        close)
            swaymsg "[con_id=$id] kill" >/dev/null
            ;;
    esac
}

case "$MODE" in
    status)
        status_output
        ;;
    action)
        action_exec
        ;;
    *)
        exit 0
        ;;
esac
