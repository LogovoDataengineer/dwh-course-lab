#!/usr/bin/env bash
# Первая настройка Metabase через его API: учётная запись администратора и подключение к базе «Полки».
# Повторный запуск ничего не меняет. Вход: admin@dwh.local / dwh-admin-123.
set -euo pipefail
MB=http://localhost:3000
api() { docker compose --profile bi exec -T metabase curl -sf -H 'Content-Type: application/json' "$@"; }
token=$(api "$MB/api/session/properties" | python3 -c "import sys,json; print(json.load(sys.stdin).get('setup-token') or '')")
if [ -n "$token" ] && api "$MB/api/session/properties" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('has-user-setup') else 1)"; then
  echo "Metabase уже настроен"; exit 0
fi
api -X POST "$MB/api/setup" -d @- >/dev/null <<JSON
{"token": "$token",
 "user": {"email": "admin@dwh.local", "password": "dwh-admin-123", "first_name": "Аналитик", "last_name": "Полки", "site_name": "Полка"},
 "prefs": {"site_name": "Полка", "site_locale": "ru", "allow_tracking": false},
 "database": {"engine": "postgres", "name": "Полка (PostgreSQL)",
              "details": {"host": "postgres", "port": 5432, "dbname": "shop", "user": "dwh", "password": "dwh", "ssl": false}}}
JSON
echo "Metabase настроен: admin@dwh.local / dwh-admin-123, база «Полка (PostgreSQL)» подключена"
