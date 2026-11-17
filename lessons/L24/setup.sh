#!/usr/bin/env bash
# Урок 24: 20 млн событий и 2 млн пользователей в озере (Parquet в MinIO), журнал запусков очищается.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d dwh -q -c "DROP TABLE IF EXISTS lab.spark_runs" 2>/dev/null || true
docker compose exec -T spark spark-submit --master 'local[4]' lessons/L24/setup.py 2>&1 | grep -E '^events|Error|Exception'
