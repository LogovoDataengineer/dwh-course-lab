#!/usr/bin/env bash
# Урок 18: топик clicks на 3 партиции и чтение его в ClickHouse (база stream). Всё с чистого листа.
set -euo pipefail
cd "$(dirname "$0")/../.."
kt() { docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 "$@"; }
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh -q "DROP DATABASE IF EXISTS stream SYNC"
kt --delete --topic clicks >/dev/null 2>&1 || true
docker compose exec -T kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group clickhouse >/dev/null 2>&1 || true
sleep 3
kt --create --topic clicks --partitions 3 --replication-factor 1 >/dev/null
kt --describe --topic clicks
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh --multiquery < lessons/L18/clickhouse.sql
