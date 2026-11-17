#!/usr/bin/env bash
# Урок 18: перечитать топик clicks с начала в ClickHouse. Потребителя останавливаем (DETACH очереди),
# сдвигаем offset группы clickhouse на начало, запускаем снова (ATTACH).
set -euo pipefail
cd "$(dirname "$0")/../.."
ch() { docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh -q "$1"; }
ch "DETACH TABLE stream.clicks_queue"; sleep 2
docker compose exec -T kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --group clickhouse --topic clicks --reset-offsets --to-earliest --execute >/dev/null
ch "ATTACH TABLE stream.clicks_queue"
echo "offset'ы группы clickhouse сброшены на начало, ClickHouse перечитывает топик"
