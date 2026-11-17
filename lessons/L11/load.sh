#!/usr/bin/env bash
# Урок 11: загрузка Data Vault за текущий день источника. Все задания — хабы, линки, сателлиты
# из lessons/L11/jobs и ваши из practice/L11 — запускаются ПАРАЛЛЕЛЬНО: хеш-ключи считаются из
# бизнес-ключей, поэтому заданиям не нужно ждать друг друга.
set -euo pipefail
cd "$(dirname "$0")/../.."
pg() { docker compose exec -T -e PGOPTIONS='-c client_min_messages=warning' postgres psql -U dwh -d dwh -v ON_ERROR_STOP=1 "$@"; }
dts=$(pg -Atc "SELECT today + time '03:00' FROM stage_dv.site_clock")
tmp=$(mktemp -d)
start=$(date +%s%N)
# DV_JOBS — другой набор заданий (так загрузку переиспользует урок 12)
for f in ${DV_JOBS:-lessons/L11/jobs/*.sql practice/L11/*.sql}; do
  job=$(basename "$f" .sql)
  (
    t0=$(date +%s%N)
    out=$(pg -v load_dts="$dts" -f "/lab/$f" 2>&1) || { echo "ОШИБКА в $f:"; echo "$out"; exit 1; }
    rows=$(printf '%s\n' "$out" | awk '/^INSERT/ {s += $3} END {print s + 0}')
    ms=$(( ($(date +%s%N) - t0) / 1000000 ))
    pg -qc "INSERT INTO dv.load_log VALUES ('$dts', '$job', $rows, $ms / 1000.0) ON CONFLICT (load_dts, job) DO UPDATE SET rows = EXCLUDED.rows, seconds = EXCLUDED.seconds"
  ) > "$tmp/$job.out" 2>&1 &
done
fail=0
for p in $(jobs -p); do wait "$p" || fail=1; done
cat "$tmp"/*.out; rm -rf "$tmp"
[ "$fail" = 0 ] || exit 1
ms=$(( ($(date +%s%N) - start) / 1000000 ))
pg -Atc "SELECT rpad(job, 22) || lpad(rows::text, 8) || ' строк  ' || seconds || ' с' FROM dv.load_log WHERE load_dts = '$dts' ORDER BY job"
n=$(ls ${DV_JOBS:-lessons/L11/jobs/*.sql practice/L11/*.sql} | wc -l)
echo "загрузка $dts: $n заданий параллельно за $((ms / 1000)),$((ms % 1000 / 100)) с"
