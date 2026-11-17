#!/usr/bin/env bash
# Урок 8: история продаж (урок 1), справочник товаров в базе сайта и пустая схема mart в хранилище.
set -euo pipefail
cd "$(dirname "$0")/../.."
lessons/L01/setup.sh
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L08/source.sql
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L08/src.sql
echo "источник: sales_history и product_catalog (видны в dwh как src.*); звезда строится в схеме mart базы dwh"
