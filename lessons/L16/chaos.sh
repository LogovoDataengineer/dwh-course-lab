#!/usr/bin/env bash
# Урок 16: загрузка дней с ненадёжной инфраструктурой. Каждую попытку с вероятностью 1/2 обрывают в случайный
# момент (так рвётся соединение, перезапускается под или кончается память), а оркестратор повторяет день,
# пока попытка не дойдёт до конца — как retries в Airflow.
#   bash lessons/L16/chaos.sh СКРИПТ ПЕРВЫЙ_ДЕНЬ [ПОСЛЕДНИЙ_ДЕНЬ]
set -euo pipefail
cd "$(dirname "$0")/../.."
script=${1:?скрипт загрузки}; from=${2:?первый день}; to=${3:-$2}
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 "$@"; }
killed=0; total=0
for day in $(pg -Atc "SELECT d::date FROM generate_series('$from'::date, '$to'::date, interval '1 day') d"); do
  try=0
  while :; do
    try=$((try + 1)); total=$((total + 1))
    docker compose exec -T -e PGAPPNAME=loader -e PGOPTIONS='-c client_min_messages=warning' postgres \
      psql -U dwh -d dwh -q -v ON_ERROR_STOP=1 -v day="$day" -f "/lab/$script" >/dev/null 2>&1 & p=$!
    if [ $((RANDOM % 2)) = 0 ]; then
      sleep "0.$((RANDOM % 9 + 1))"
      pg -Atc "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'loader'" >/dev/null
    fi
    if wait $p; then outcome=ok; else outcome=killed; killed=$((killed + 1)); fi
    pg -c "INSERT INTO rel.attempts (script, day, try, outcome) VALUES ('$script', '$day', $try, '$outcome')"
    [ "$outcome" = ok ] && break
  done
done
echo "попыток $total, оборвано $killed"
pg -f /lab/lessons/L16/reconcile.sql
