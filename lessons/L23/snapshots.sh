#!/usr/bin/env bash
# Урок 23: история таблицы lake.shop.orders глазами Trino — снимки и выручка таблицы в каждом из них (time travel).
cd "$(dirname "$0")/../.."
tr() { docker compose exec -T trino trino --output-format ALIGNED --execute "$1" 2>/dev/null; }
ids=$(docker compose exec -T trino trino --output-format TSV --execute \
  "SELECT snapshot_id FROM iceberg.shop.\"orders\$snapshots\" ORDER BY committed_at" 2>/dev/null)
sql=""
for id in $ids; do
  [ -n "$sql" ] && sql="$sql UNION ALL "
  sql="${sql}SELECT $id AS snapshot_id, count(*) AS orders, sum(amount) AS revenue FROM iceberg.shop.orders FOR VERSION AS OF $id"
done
tr "SELECT s.committed_at, s.snapshot_id, s.operation, h.is_current_ancestor AS in_current_history, r.orders, r.revenue
    FROM iceberg.shop.\"orders\$snapshots\" s
    JOIN iceberg.shop.\"orders\$history\" h ON h.snapshot_id = s.snapshot_id
    JOIN ($sql) r ON r.snapshot_id = s.snapshot_id
    ORDER BY s.committed_at"
