#!/usr/bin/env bash
# Урок 11: проходят дни на сайте и в CRM, каждый день загружается в Data Vault.
#   bash lessons/L11/day.sh 3   — три дня подряд
set -euo pipefail
cd "$(dirname "$0")/../.."
for _ in $(seq "${1:-1}"); do
  docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L11/tick.sql
  bash lessons/L11/load.sh >/dev/null
  docker compose exec -T postgres psql -U dwh -d dwh -At -F ' | ' -c "
    SELECT load_dts::date, 'хабы +' || sum(rows) FILTER (WHERE job LIKE 'hub%'), 'линки +' || sum(rows) FILTER (WHERE job LIKE 'link%'),
           'сателлиты +' || sum(rows) FILTER (WHERE job LIKE 'sat%'), 'за ' || replace((max(seconds))::text, '.', ',') || ' с'
    FROM dv.load_log WHERE load_dts = (SELECT max(load_dts) FROM dv.load_log) GROUP BY load_dts"
done
