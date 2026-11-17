#!/usr/bin/env bash
# Урок 18: offset'ы и lag группы clickhouse по партициям топика clicks.
cd "$(dirname "$0")/../.."
docker compose exec -T kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group clickhouse 2>/dev/null \
  | awk '$1 == "GROUP" || $2 == "clicks" {printf "%-11s %-7s %-10s %-15s %-15s %s\n", $1, $2, $3, $4, $5, $6}' | (read -r h; echo "$h"; sort -k3n)
