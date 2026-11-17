#!/usr/bin/env bash
# Урок 22: посадочная зона озера — 14 дней событий сайта в JSON по часам (около минуты, Spark).
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose --profile lake exec -T minio mc alias set local http://localhost:9000 dwhadmin dwh-admin-123 >/dev/null
docker compose --profile lake exec -T minio mc rm -r --force local/lake/raw local/lake/curated >/dev/null 2>&1 || true
docker compose --profile lake exec -T spark spark-submit --master 'local[2]' lessons/L22/land.py 2>&1 | grep -vE '^[0-9]{2}/[0-9]{2}/[0-9]{2} |WARN'
