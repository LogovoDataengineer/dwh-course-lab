#!/usr/bin/env bash
# Урок 15: приложение работает N секунд, а хранилище всё это время забирает изменения скриптом загрузки
# каждые 2 секунды; после остановки приложения — последняя загрузка и сверка с источником.
#   bash lessons/L15/run.sh lessons/L15/load_naive.sql 40
set -euo pipefail
cd "$(dirname "$0")/../.."
script=${1:?скрипт загрузки}; secs=${2:-40}
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -q -v ON_ERROR_STOP=1 "$@"; }
run=$(pg -d dwh -Atc "SELECT coalesce(max(run_id), 0) + 1 FROM inc.runs")
echo "== Прогон $run: приложение работает $secs с, загрузка $script каждые 2 с"
pg -d shop -c "CALL app.work_fast($secs)" & fast=$!
pg -d shop -c "CALL app.work_slow($secs)" & slow=$!
loads=0
while kill -0 $fast 2>/dev/null || kill -0 $slow 2>/dev/null; do
  pg -d dwh -v run="$run" -f "/lab/$script" >/dev/null; loads=$((loads + 1))
  sleep 2
done
wait $fast $slow
pg -d dwh -v run="$run" -f "/lab/$script" >/dev/null; loads=$((loads + 1))
pg -d dwh -Atc "SELECT 'загрузок ' || count(*) || ', прочитано строк в среднем ' || round(avg(rows_read)) || ', максимум ' || max(rows_read)
                FROM inc.load_log WHERE run_id = $run"
pg -d dwh -c "INSERT INTO inc.runs (run_id, script, seconds, loads, src_rows, missed)
              SELECT $run, '$script', $secs, $loads, count(*),
                     count(*) FILTER (WHERE o.order_id IS NULL OR (o.status, o.amount, o.updated_at) IS DISTINCT FROM (s.status, s.amount, s.updated_at))
              FROM inc.src_orders s LEFT JOIN inc.orders o USING (order_id)" >/dev/null
pg -d dwh -f /lab/lessons/L15/reconcile.sql
