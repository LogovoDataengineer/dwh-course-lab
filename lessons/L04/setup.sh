#!/usr/bin/env bash
# Урок 4: история продаж (урок 1) и журнал событий приложения за ноябрь.
set -euo pipefail
cd "$(dirname "$0")/../.."
lessons/L01/setup.sh
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L04/setup.sql
