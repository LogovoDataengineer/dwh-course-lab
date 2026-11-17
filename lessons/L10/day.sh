#!/usr/bin/env bash
# Урок 10: проходят дни в CRM, и каждый день загружается в хранилище.
#   bash lessons/L10/day.sh 5     — пять дней подряд
# День: tick.sql меняет CRM → load_scd2.sql (SCD2 и заказы дня) → practice/L10/*.sql (ваш SCD1).
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
for _ in $(seq "${1:-1}"); do
  pg -d shop -f /lab/lessons/L10/tick.sql
  pg -d dwh -f /lab/lessons/L10/load_scd2.sql
  for f in practice/L10/*.sql; do pg -d dwh -f "/lab/$f"; done
  pg -d dwh -At -F ' | ' -c "SELECT load_date, 'закрыто версий ' || closed, 'новых версий ' || inserted, 'заказов ' || orders FROM scd.load_log ORDER BY load_date DESC LIMIT 1"
done
