#!/usr/bin/env bash
# Урок 12: Data Vault урока 11 с нуля и 9 дней загрузки (сайт и CRM), призрачные записи и пустая PIT.
set -euo pipefail
cd "$(dirname "$0")/../.."
source lessons/L12/jobs.sh
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
pg -d shop -f /lab/lessons/L11/source.sql
pg -d dwh -f /lab/lessons/L08/src.sql -o /dev/null
pg -d dwh -f /lab/lessons/L11/init.sql
bash lessons/L11/load.sh >/dev/null
for _ in $(seq 9); do
  pg -d shop -f /lab/lessons/L11/tick.sql
  bash lessons/L11/load.sh | tail -1
done
pg -d dwh -f /lab/lessons/L12/init.sql
