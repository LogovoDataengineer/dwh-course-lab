#!/usr/bin/env bash
# Урок 14: сборка модели «Полки» с нуля — STG, ваши файлы practice/L14/*.sql по порядку номеров, сверка.
# Файл, где ещё стоит «SELECT ...», пропускается: его шаг вы пока не написали.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 "$@"; }
run() {
  local f=$1 t0=$(date +%s%N)
  if grep -q '^SELECT \.\.\.' "$f"; then echo "  $(basename "$f") — ещё не написан, пропускаю"; return; fi
  pg -f "/lab/$f" || { echo "  ОШИБКА в $f"; exit 1; }
  local ms=$(( ($(date +%s%N) - t0) / 1000000 ))
  echo "  $(basename "$f") — $((ms / 1000)),$((ms % 1000 / 100)) с"
}
echo "== STG: копия источников"
run lessons/L14/00_stage.sql
echo "== Модель"
for f in practice/L14/[1-5]*.sql; do run "$f"; done
if pg -Atc "SELECT to_regclass('polka.fact_sales') IS NOT NULL" | grep -q t; then
  echo "== Сверка"
  pg -f /lab/lessons/L14/60_reconcile.sql
fi
echo "== Витрины"
for f in practice/L14/[6-9]*.sql; do run "$f"; done
