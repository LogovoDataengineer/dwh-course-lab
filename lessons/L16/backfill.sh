#!/usr/bin/env bash
# Урок 16: backfill — перегрузить скриптом загрузки только дни, где хранилище разошлось с источником.
#   bash lessons/L16/backfill.sh practice/L16/load_day.sql
set -euo pipefail
cd "$(dirname "$0")/../.."
script=${1:?скрипт загрузки}
days=$(docker compose exec -T postgres psql -U dwh -d dwh -At -f /lab/lessons/L16/bad_days.sql | cut -d'|' -f1)
[ -n "$days" ] || { echo "расходящихся дней нет"; exit 0; }
for d in $days; do echo "== backfill $d"; bash lessons/L16/chaos.sh "$script" "$d" | sed -n 1p; done
docker compose exec -T postgres psql -U dwh -d dwh -f /lab/lessons/L16/reconcile.sql
