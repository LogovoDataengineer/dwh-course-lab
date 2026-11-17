#!/usr/bin/env bash
# Урок 21: нагрузка на базу — 4 клиента 20 секунд выполняют вперемешку четыре запроса приложения и BI.
# pgbench показывает, сколько транзакций в секунду прошло и среднюю задержку каждого запроса.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d shop -qc "SELECT pg_stat_statements_reset()" >/dev/null
docker compose exec -T postgres pgbench -U dwh -n -c 4 -j 4 -T "${1:-20}" -r \
  -f /lab/lessons/L21/q1_customer_orders.sql -f /lab/lessons/L21/q2_day_revenue.sql \
  -f /lab/lessons/L21/q3_login.sql -f /lab/lessons/L21/q4_processing.sql shop 2>&1 \
  | grep -E '^(tps|latency average|SQL script [0-9]| - [0-9]+ transactions| +[0-9.]+ +[0-9]+ +SELECT)' | sed 's/ (without initial connection time)//'
