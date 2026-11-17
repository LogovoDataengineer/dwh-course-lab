#!/usr/bin/env bash
# Урок 12: следующий день — источники, загрузка Data Vault, затем ваш файл practice/L12/pit_day.sql
# (снимок PIT на новую дату) и пересборка bridge. Запуск: bash lessons/L12/day.sh [дней]
set -euo pipefail
cd "$(dirname "$0")/../.."
source lessons/L12/jobs.sh
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
for _ in $(seq "${1:-1}"); do
  pg -d shop -f /lab/lessons/L11/tick.sql
  bash lessons/L11/load.sh | tail -1
  day=$(pg -d dwh -Atc "SELECT today FROM stage_dv.site_clock")
  pg -d dwh -v day="$day" -f /lab/practice/L12/pit_day.sql
  pg -d dwh -f /lab/lessons/L12/bridge.sql
  pg -d dwh -At -F ' | ' -c "SELECT 'PIT: снимков ' || count(DISTINCT snapshot_date), 'последний ' || max(snapshot_date), 'строк ' || count(*) FROM dv.pit_customer"
done
