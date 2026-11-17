#!/usr/bin/env bash
# Урок 5: проходит час — источник меняется (tick.sql), затем загрузка хранилища (load.sql).
# Несколько часов подряд: for i in $(seq 24); do bash lessons/L05/hour.sh; done
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L05/tick.sql -o /dev/null
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L05/load.sql -P footer=off
