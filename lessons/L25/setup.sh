#!/usr/bin/env bash
# Урок 25: заказы 1–14 марта в базе сайта и пустые витрины в хранилище; DAG урока лежат в airflow/dags.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L25/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L25/init.sql
af() { docker compose --profile airflow exec -T airflow airflow "$@" 2>/dev/null; }
for d in l25_naive daily_revenue; do af dags delete -y "$d" >/dev/null || true; done
echo "Заказы в базе сайта:"
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT created_at::date AS day, count(*) AS orders FROM af.orders GROUP BY 1 ORDER BY 1 LIMIT 3"
