#!/usr/bin/env bash
# Первая настройка Metabase через его API: учётная запись администратора и подключение к базе «Полки».
# Повторный запуск ничего не меняет. Вход: admin@dwh.local / dwh-admin-123.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, urllib.request
MB = "http://localhost:3000"
def call(method, path, body=None, sid=None):
    headers = {"Content-Type": "application/json"}
    if sid:
        headers["X-Metabase-Session"] = sid
    req = urllib.request.Request(MB + path, method=method, headers=headers,
                                 data=json.dumps(body).encode() if body is not None else None)
    return json.load(urllib.request.urlopen(req))
props = call("GET", "/api/session/properties")
if not props.get("has-user-setup"):
    call("POST", "/api/setup", {"token": props["setup-token"],
         "user": {"email": "admin@dwh.local", "password": "dwh-admin-123", "first_name": "Аналитик", "last_name": "Полки", "site_name": "Полка"},
         "prefs": {"site_name": "Полка", "site_locale": "ru", "allow_tracking": False}})
sid = call("POST", "/api/session", {"username": "admin@dwh.local", "password": "dwh-admin-123"})["id"]
if not any(d["engine"] == "postgres" for d in call("GET", "/api/database", sid=sid)["data"]):
    call("POST", "/api/database", {"engine": "postgres", "name": "Полка (PostgreSQL)",
         "details": {"host": "postgres", "port": 5432, "dbname": "shop", "user": "dwh", "password": "dwh", "ssl": False}}, sid)
print("Metabase готов: admin@dwh.local / dwh-admin-123, база «Полка (PostgreSQL)» подключена")
PY
