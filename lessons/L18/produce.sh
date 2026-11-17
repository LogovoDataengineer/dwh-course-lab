#!/usr/bin/env bash
# Урок 18: поток кликов в топик clicks — N секунд со скоростью R событий в секунду.
#   bash lessons/L18/produce.sh 60 300
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 lessons/L18/produce.py "${1:-60}" "${2:-300}" \
  | docker compose exec -T kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 \
      --topic clicks --property parse.key=true --property key.separator='|'
