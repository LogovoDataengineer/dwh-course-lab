#!/usr/bin/env bash
# Урок 23: загрузить дни по порядку заданием загрузки (по умолчанию — правильным merge_day.py).
#   bash lessons/L23/load.sh 2026-03-01 2026-03-03 [lessons/L23/merge_day.py]
set -euo pipefail
cd "$(dirname "$0")/../.."
job=${3:-lessons/L23/merge_day.py}
d=$1
while [[ "$d" < "$2" || "$d" == "$2" ]]; do
  docker compose exec -T spark spark-submit --master 'local[2]' "$job" "$d" 2>&1 | grep -E "^$d|Error|Exception" || true
  d=$(date -I -d "$d + 1 day")
done
