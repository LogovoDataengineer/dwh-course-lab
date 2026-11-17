#!/usr/bin/env bash
# Урок 5: источник (старая система заказов в базе сайта) и пустое хранилище в базе dwh.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L05/source.sql
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L05/dwh_init.sql
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 \
  -c "\copy stg.crm_contacts_raw (contact_id, name, email, phone) FROM '/lab/lessons/L05/crm_contacts.csv' WITH (FORMAT csv, HEADER true)"
echo "источник: таблица legacy_orders в базе shop; хранилище: база dwh, схемы stg, ods, dds, cdm, meta"
