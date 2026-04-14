#!/bin/bash

# Alternância visual de janelas no Sway com Wofi
# Uso: alt_tab_visual.sh [next|prev] [cooldown_ms]

set -euo pipefail

DIRECTION="${1:-next}"
COOLDOWN_MS="${2:-300}"

if [ "$DIRECTION" != "next" ] && [ "$DIRECTION" != "prev" ]; then
    DIRECTION="next"
fi

if ! [[ "$COOLDOWN_MS" =~ ^[0-9]+$ ]]; then
    COOLDOWN_MS=300
fi

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway-alt-tab"
LOCK_DIR="$STATE_DIR/lock"
STAMP_FILE="$STATE_DIR/last_run_ms"

mkdir -p "$STATE_DIR"

# Impede abrir várias instâncias do seletor ao pressionar Alt+Tab repetidamente
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi

cleanup() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

if NOW_MS="$(date +%s%3N 2>/dev/null)" && [[ "$NOW_MS" =~ ^[0-9]+$ ]]; then
    :
else
    NOW_MS=$(( $(date +%s) * 1000 ))
fi

LAST_MS=0
if [ -f "$STAMP_FILE" ]; then
    LAST_MS="$(cat "$STAMP_FILE" 2>/dev/null || echo 0)"
fi

if ! [[ "$LAST_MS" =~ ^[0-9]+$ ]]; then
    LAST_MS=0
fi

if [ $((NOW_MS - LAST_MS)) -lt "$COOLDOWN_MS" ]; then
    exit 0
fi

echo "$NOW_MS" > "$STAMP_FILE"

if ! command -v swaymsg >/dev/null 2>&1; then
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    notify-send "Sway" "Instale jq para usar Alt+Tab visual"
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    # Fallback para navegação simples caso o wofi não exista
    if [ "$DIRECTION" = "prev" ]; then
        swaymsg focus prev >/dev/null
    else
        swaymsg focus next >/dev/null
    fi
    exit 0
fi

TREE_JSON="$(swaymsg -t get_tree)"

# workspace atual focado (mais confiável via get_workspaces)
CURRENT_WORKSPACE="$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name' | head -n1)"

if [ -z "$CURRENT_WORKSPACE" ]; then
    exit 0
fi

# Lista janelas visíveis no workspace atual (id + nome)
WINDOWS="$(printf '%s' "$TREE_JSON" | jq -r --arg ws "$CURRENT_WORKSPACE" '
  .. | objects
  | select(.type? == "workspace" and .name? == $ws)
  | .. | objects
  | select((.type? == "con" or .type? == "floating_con") and (.app_id? != null or .window_properties? != null))
  | [.id, (.name // "Janela sem título")] | @tsv
')"

if [ -z "$WINDOWS" ]; then
    exit 0
fi

# Remove duplicados de id preservando ordem
WINDOWS_UNIQ="$(printf '%s\n' "$WINDOWS" | awk -F'\t' '!seen[$1]++')"

FOCUSED_ID="$(printf '%s' "$TREE_JSON" | jq -r '.. | objects | select(.focused? == true and (.type? == "con" or .type? == "floating_con")) | .id' | head -n1)"

# Monta lista com destaque da janela atual
MENU_ENTRIES="$(printf '%s\n' "$WINDOWS_UNIQ" | awk -F'\t' -v focused="$FOCUSED_ID" '
{
  prefix = ($1 == focused) ? "● " : "  "
  print prefix $2 "\t" $1
}')"

# Seleção por menu
SELECTED_LINE="$(printf '%s\n' "$MENU_ENTRIES" | cut -f1 | wofi --dmenu --insensitive --prompt "Alt+Tab ($CURRENT_WORKSPACE)" --lines 12)"

if [ -z "$SELECTED_LINE" ]; then
    # Se cancelou o menu, faz fallback direcional
    if [ "$DIRECTION" = "prev" ]; then
        swaymsg focus prev >/dev/null
    else
        swaymsg focus next >/dev/null
    fi
    exit 0
fi

SELECTED_ID="$(printf '%s\n' "$MENU_ENTRIES" | awk -F'\t' -v sel="$SELECTED_LINE" '$1==sel{print $2; exit}')"

if [ -n "$SELECTED_ID" ]; then
    swaymsg "[con_id=$SELECTED_ID] focus" >/dev/null

    # Para janelas flutuantes, força trazer para frente de forma consistente.
    IS_FLOATING="$(printf '%s' "$TREE_JSON" | jq -r --argjson id "$SELECTED_ID" '.. | objects | select(.id? == $id) | .floating // "auto_off"' | head -n1)"
    if [[ "$IS_FLOATING" == *"_on" ]]; then
        MARK="__raise_${SELECTED_ID}"
        swaymsg "[con_id=$SELECTED_ID] mark $MARK" >/dev/null
        swaymsg "[con_mark=$MARK] move scratchpad" >/dev/null
        swaymsg "[con_mark=$MARK] scratchpad show" >/dev/null
        swaymsg "[con_mark=$MARK] focus" >/dev/null
        swaymsg "[con_mark=$MARK] unmark $MARK" >/dev/null
    fi
fi
