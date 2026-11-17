#!/usr/bin/env bash
# Урок 20: каталог товаров в PostgreSQL, 20 млн продаж и статусы заказов в ClickHouse.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L20/source_pg.sql
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh --multiquery < lessons/L20/source_ch.sql
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh --format PrettyCompactMonoBlock -q "
  SELECT table, sum(rows) AS rows, formatReadableSize(sum(bytes_on_disk)) AS on_disk, count() AS parts
  FROM system.parts WHERE database = 'shop' AND active GROUP BY table ORDER BY table"
