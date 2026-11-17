#!/usr/bin/env bash
# Урок 27: факт заказов за март с четырьмя инцидентами загрузки (схема dq базы dwh).
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L27/source.sql
docker compose exec -T postgres psql -U dwh -d dwh -c "SELECT count(*) AS rows, count(DISTINCT order_date) AS days, min(order_date), max(order_date) FROM dq.fact_orders"
