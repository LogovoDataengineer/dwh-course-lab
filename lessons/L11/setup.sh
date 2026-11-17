#!/usr/bin/env bash
# Урок 11: два источника в базе сайта, схема dv в хранилище и первая загрузка Data Vault.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L11/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L11/init.sql
bash lessons/L11/load.sh
