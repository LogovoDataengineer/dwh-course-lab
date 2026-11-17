#!/usr/bin/env bash
# Урок 17: приложение магазина работает N секунд — создаёт, меняет и удаляет заказы в cdc.orders.
#   bash lessons/L17/app.sh 30
set -euo pipefail
cd "$(dirname "$0")/../.."
secs=${1:-30}
before=$(docker compose exec -T postgres psql -U dwh -d shop -Atc "SELECT pg_current_wal_lsn()")
docker compose exec -T postgres psql -U dwh -d shop -q -c "CALL cdc.work($secs)"
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT count(*) AS orders_now, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '$before')) AS wal_written FROM cdc.orders"
