#!/usr/bin/env bash
# Урок 6: история продаж (урок 1) и плоская выгрузка norm.sales_flat в базе shop.
set -euo pipefail
cd "$(dirname "$0")/../.."
lessons/L01/setup.sh
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L06/setup.sql
