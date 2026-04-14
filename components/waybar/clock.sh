#!/bin/bash

# Relogio custom para Waybar (JSON)

set -euo pipefail

NOW_TEXT="$(date '+%d/%m/%Y - %H:%M')"
NOW_TIP="$(date '+%A, %d de %B de %Y\n%H:%M:%S')"

echo "{\"text\":\" ${NOW_TEXT}\",\"tooltip\":\"${NOW_TIP}\"}"
