#!/bin/bash

# Módulo de velocidade de rede para Waybar
# Saída JSON: download/upload em tempo real

set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway-net-speed"
STATE_FILE="$STATE_DIR/state"
mkdir -p "$STATE_DIR"

get_default_iface() {
    ip route 2>/dev/null | awk '/^default/ {print $5; exit}'
}

format_rate() {
    local bps="$1"
    if [ "$bps" -ge 1048576 ]; then
        awk -v v="$bps" 'BEGIN { printf "%.1f MB/s", v/1048576 }'
    elif [ "$bps" -ge 1024 ]; then
        awk -v v="$bps" 'BEGIN { printf "%.1f KB/s", v/1024 }'
    else
        printf "%d B/s" "$bps"
    fi
}

iface="$(get_default_iface)"
if [ -z "$iface" ] || [ ! -d "/sys/class/net/$iface/statistics" ]; then
    echo '{"text":"󰤮 offline","tooltip":"Sem interface de rede ativa","class":"disconnected"}'
    exit 0
fi

rx_now="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
tx_now="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
now_ts="$(date +%s)"

if [ -f "$STATE_FILE" ]; then
    read -r last_ts last_rx last_tx last_iface < "$STATE_FILE" || true
else
    last_ts="$now_ts"
    last_rx="$rx_now"
    last_tx="$tx_now"
    last_iface="$iface"
fi

# Reinicia medição se a interface mudou ou se timestamp inválido
if [ "${last_iface:-}" != "$iface" ] || [ -z "${last_ts:-}" ] || [ "$now_ts" -le "${last_ts:-0}" ]; then
    last_ts="$now_ts"
    last_rx="$rx_now"
    last_tx="$tx_now"
fi

delta_t=$((now_ts - last_ts))
if [ "$delta_t" -lt 1 ]; then
    delta_t=1
fi

delta_rx=$((rx_now - last_rx))
delta_tx=$((tx_now - last_tx))
if [ "$delta_rx" -lt 0 ]; then delta_rx=0; fi
if [ "$delta_tx" -lt 0 ]; then delta_tx=0; fi

rx_rate=$((delta_rx / delta_t))
tx_rate=$((delta_tx / delta_t))

rx_fmt="$(format_rate "$rx_rate")"
tx_fmt="$(format_rate "$tx_rate")"

printf '%s %s %s %s\n' "$now_ts" "$rx_now" "$tx_now" "$iface" > "$STATE_FILE"

echo "{\"text\":\"⬇ ${rx_fmt} ⬆ ${tx_fmt}\",\"tooltip\":\"Interface: ${iface}\\nDownload: ${rx_fmt}\\nUpload: ${tx_fmt}\"}"
