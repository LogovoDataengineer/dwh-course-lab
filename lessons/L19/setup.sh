#!/usr/bin/env bash
# Урок 19: данные урока в Greenplum (схема mpp базы shop).
set -euo pipefail
cd "$(dirname "$0")/../.."
gp() { docker compose exec -T greenplum su - gpadmin -c "psql -d shop -q -v ON_ERROR_STOP=1 $*"; }
gp "-f /lab/lessons/L19/source.sql"
printf '%s\n' "SELECT 'fact_sales' AS table_name, count(*) AS rows FROM mpp.fact_sales UNION ALL SELECT 'orders', count(*) FROM mpp.orders UNION ALL SELECT 'payments', count(*) FROM mpp.payments UNION ALL SELECT 'dim_customer', count(*) FROM mpp.dim_customer;" \
  | docker compose exec -T greenplum su - gpadmin -c "psql -d shop"
