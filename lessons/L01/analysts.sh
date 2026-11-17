#!/usr/bin/env bash
# Урок 1: N аналитиков одновременно гоняют отчёт, пока идёт замер нагрузки сайта.
# Использование: bash lessons/L01/analysts.sh pg 4 40   (по базе сайта: 4 аналитика, 40 секунд)
#                bash lessons/L01/analysts.sh ch 4 40   (тот же отчёт по ClickHouse)
set -uo pipefail
cd "$(dirname "$0")/../.."
TARGET=${1:-pg}; N=${2:-4}; DURATION=${3:-40}
end=$((SECONDS + DURATION)); runs=0
run_report() {
  if [ "$TARGET" = ch ]; then
    docker compose exec -T clickhouse clickhouse-client --user dwh --password dwh --format Null < lessons/L01/report_ch.sql
  else
    docker compose exec -T postgres psql -U dwh -d shop -q -o /dev/null -f /lab/lessons/L01/report.sql
  fi
}
for i in $(seq "$N"); do
  ( n=0; while [ $SECONDS -lt $end ]; do run_report; n=$((n + 1)); done; echo "$n" > "/tmp/analyst-$i" ) &
done
wait
total=$(cat /tmp/analyst-* | paste -sd+ | bc); rm -f /tmp/analyst-*
echo "аналитики ($TARGET) выполнили отчёт $total раз за $DURATION с"
