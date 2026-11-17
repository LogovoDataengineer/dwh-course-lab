#!/usr/bin/env bash
# Урок 21: покупатели и заказы в схеме perf базы сайта, расширение pg_stat_statements.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L21/source.sql
docker compose exec -T postgres psql -U dwh -d shop -c "SELECT relname AS table_name, n_live_tup AS rows, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_stat_user_tables WHERE schemaname = 'perf' ORDER BY relname"
