#!/usr/bin/env bash
# Урок 2: та же история продаж, что в уроке 1, — в PostgreSQL и копия в ClickHouse (если её ещё нет).
set -euo pipefail
cd "$(dirname "$0")/../.."
lessons/L01/setup.sh
have=$(docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh -q "SELECT count() FROM system.tables WHERE database = 'dwh' AND name = 'sales_history'")
if [ "$have" != 1 ]; then
  echo "копируем историю в ClickHouse (как в уроке 1)…"
  docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh --multiquery < lessons/L01/to_clickhouse.sql >/dev/null
fi
