#!/usr/bin/env bash
# Урок 7: чистое хранилище в базе dwh для практикума (слои stg, ods, cdm, журнал meta).
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose exec -T postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -f /lab/lessons/L07/init.sql
echo "хранилище dwh пересоздано; выгрузки ждут в lessons/L07/inbox: batch_001, batch_002, batch_003"
