#!/usr/bin/env bash
# Урок 14: источники «Полки» в базе сайта (схема polka) и сервер postgres_fdw в хранилище.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L14/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -c "DROP SCHEMA IF EXISTS polka CASCADE; DROP SCHEMA IF EXISTS polka_stg CASCADE"
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT (SELECT count(*) FROM polka.customers) AS customers, (SELECT count(*) FROM polka.orders) AS orders, (SELECT count(*) FROM polka.order_items) AS order_items, (SELECT count(*) FROM polka.payments) AS payments"
