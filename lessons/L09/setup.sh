#!/usr/bin/env bash
# Урок 9: события заказов за ноябрь в базе сайта и пустая схема flow в хранилище.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L09/source.sql
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L08/src.sql -o /dev/null
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L09/init.sql
