#!/usr/bin/env bash
# Урок 15: приложение магазина в базе сайта (схема app) и схема inc в хранилище.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L15/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L15/init.sql
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT count(*) AS orders, max(updated_at)::timestamp(0) AS last_change FROM app.orders"
