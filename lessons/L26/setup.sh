#!/usr/bin/env bash
# Урок 26: dbt-проект «Полки» (dbt/shop) с чистыми схемами и заказы мобильного приложения в базе сайта.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 "$@"; }
pg -c "DROP SCHEMA IF EXISTS stg CASCADE; DROP SCHEMA IF EXISTS cdm CASCADE; DROP SCHEMA IF EXISTS snapshots CASCADE; DROP SCHEMA IF EXISTS dbt_test__audit CASCADE"
pg -f /lab/lessons/L26/source_changes.sql
rm -rf dbt/shop/target dbt/shop/logs
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT status, count(*) AS orders FROM orders GROUP BY status ORDER BY status"
