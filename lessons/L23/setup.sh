#!/usr/bin/env bash
# Урок 23: таблица Iceberg с миллионом заказов и изменения за 1–5 марта в посадочной зоне (около минуты).
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T spark spark-submit --master 'local[2]' lessons/L23/setup.py 2>&1 | grep -vE '^[0-9]{2}/[0-9]{2}/[0-9]{2} |WARN'
