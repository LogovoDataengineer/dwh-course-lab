#!/usr/bin/env bash
# Урок 13: сервис такси в базе сайта (схема taxi): водители, класс автомобиля по SCD2, 2 млн поездок, оплаты.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L13/source.sql
docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh -q "DROP DATABASE IF EXISTS taxi"
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT (SELECT count(*) FROM taxi.trips) AS trips, (SELECT count(*) FROM taxi.trip_payments) AS payments, (SELECT count(*) FROM taxi.drivers) AS drivers"
