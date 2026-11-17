#!/usr/bin/env bash
# Урок 17: источник cdc.orders в базе сайта; старые коннектор, слот, топик и таблицы ClickHouse убираются,
# чтобы урок начинался с чистого листа.
set -euo pipefail
cd "$(dirname "$0")/../.."
# коннектор с прошлого запуска: остановить, стереть его позицию в журнале (иначе новый не сделает снимок) и удалить
if curl -sf localhost:8083/connectors/shop-cdc >/dev/null; then
  curl -s -X PUT localhost:8083/connectors/shop-cdc/stop >/dev/null; sleep 3
  curl -s -X DELETE localhost:8083/connectors/shop-cdc/offsets >/dev/null
  curl -s -X DELETE localhost:8083/connectors/shop-cdc >/dev/null
fi
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh -q "DROP DATABASE IF EXISTS cdc SYNC"
docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic shop.cdc.orders >/dev/null 2>&1 || true
docker compose exec -T kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group clickhouse_cdc >/dev/null 2>&1 || true
sleep 2
docker compose exec -T postgres psql -U dwh -d shop -q -c "SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots WHERE slot_name = 'dwh_cdc'" -o /dev/null
docker compose exec -T -e PGOPTIONS="-c client_min_messages=warning" postgres psql -U dwh -d shop -q -c "DROP PUBLICATION IF EXISTS dwh_cdc"
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L17/source.sql
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT count(*) AS orders, current_setting('wal_level') AS wal_level FROM cdc.orders"
