#!/usr/bin/env bash
# Урок 1: история продаж в PostgreSQL (5 млн строк) и таблицы для замера нагрузки сайта.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d shop -q -v ON_ERROR_STOP=1 -f /lab/lessons/L01/setup.sql
