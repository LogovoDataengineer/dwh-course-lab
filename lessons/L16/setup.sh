#!/usr/bin/env bash
# Урок 16: продажи февраля в базе сайта (схема rel) и пустые факт и витрина в хранилище.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L16/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L16/init.sql
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT count(*) AS sales, min(sold_at)::date AS first_day, max(sold_at)::date AS last_day FROM rel.sales"
