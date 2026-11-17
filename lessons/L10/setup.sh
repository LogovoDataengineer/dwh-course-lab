#!/usr/bin/env bash
# Урок 10: CRM в базе сайта и схема scd в хранилище; первая загрузка — все покупатели на 31 октября.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L10/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L10/init.sql
pg -d dwh -f /lab/lessons/L10/load_scd2.sql
pg -d dwh -c "SELECT count(*) AS customers, min(valid_from) AS valid_from FROM scd.dim_customer"
