#!/usr/bin/env bash
# Урок 9: загрузить события одного или нескольких дней в накопительный снимок.
#   bash lessons/L09/day.sh 2025-11-01               — один день
#   bash lessons/L09/day.sh 2025-11-01 2025-12-10    — все дни с первого по второй включительно
set -euo pipefail
cd "$(dirname "$0")/../.."
from=${1:?дата}; to=${2:-$1}
d=$from
while [[ "$d" < "$to" || "$d" == "$to" ]]; do
  docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 \
    -v day="$d" -f /lab/lessons/L09/load_day.sql -P footer=off | { if [ "$from" = "$to" ]; then cat; else grep -v '^$' | tail -n 1; fi; }
  d=$(date -I -d "$d + 1 day")
done
