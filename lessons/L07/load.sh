#!/usr/bin/env bash
# Урок 7: загрузка одной выгрузки из inbox через слои хранилища.
#   bash lessons/L07/load.sh 1      — выгрузка lessons/L07/inbox/batch_001
# Повторный запуск той же выгрузки безопасен: её строки в STG сначала удаляются.
# Шаги загрузки — файлы practice/L07/*.sql по порядку имён: их вы и правите в практике.
set -euo pipefail
cd "$(dirname "$0")/../.."
N=$((10#${1:?номер выгрузки}))
DIR=lessons/L07/inbox/$(printf 'batch_%03d' "$N")
[ -d "$DIR" ] || { echo "нет выгрузки $DIR"; exit 1; }
psql() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -v batch="$N" "$@"; }
echo "== выгрузка $N: STG"
psql -c "DELETE FROM stg.customers_raw WHERE batch_id = $N" -c "DELETE FROM stg.orders_raw WHERE batch_id = $N"
psql -c "\copy stg.customers_raw (customer_id, full_name, email, city, updated_at) FROM '/lab/$DIR/customers.csv' WITH (FORMAT csv, HEADER true)" \
     -c "\copy stg.orders_raw (order_id, customer_id, created_at, status, amount) FROM '/lab/$DIR/orders.csv' WITH (FORMAT csv, HEADER true)" \
     -c "UPDATE stg.customers_raw SET batch_id = $N WHERE batch_id = 0" -c "UPDATE stg.orders_raw SET batch_id = $N WHERE batch_id = 0"
for step in practice/L07/*.sql; do
  echo "== выгрузка $N: $(basename "$step")"
  psql -f "/lab/$step"
done
psql -P footer=off -c "SELECT batch_id, rows_loaded AS ods_orders, rows_rejected AS rejected, lost FROM meta.load_log ORDER BY loaded_at DESC LIMIT 1"
