#!/usr/bin/env bash
# Урок 24: запустить задание Spark на 4 ядрах, записать время в журнал запусков (база dwh, таблица lab.spark_runs).
#   bash lessons/L24/run.sh lessons/L24/job.py baseline
set -euo pipefail
cd "$(dirname "$0")/../.."
script=${1:?скрипт задания}; name=${2:?имя запуска}
out=$(docker compose exec -T spark spark-submit --master 'local[4]' "$script" "$name" 2>&1 | grep -E "^$name: |Error|Exception" || true)
echo "$out"
secs=$(echo "$out" | sed -n "s/^$name: \([0-9.]*\) с$/\1/p")
[ -n "$secs" ] || { echo "задание не завершилось — смотрите вывод выше"; exit 1; }
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -c "CREATE SCHEMA IF NOT EXISTS lab;
  CREATE TABLE IF NOT EXISTS lab.spark_runs (name text, script text, seconds numeric, at timestamptz DEFAULT now());
  INSERT INTO lab.spark_runs (name, script, seconds) VALUES ('$name', '$script', $secs);"
