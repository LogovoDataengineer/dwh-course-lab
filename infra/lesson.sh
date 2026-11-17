#!/usr/bin/env bash
# make lesson-NN: поднимает сервисы урока NN, останавливает тяжёлые сервисы других уроков
# (в Codespace 16 ГБ памяти, всё сразу держать незачем) и готовит данные урока (lessons/LNN/setup.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
N=$(printf '%02d' "$((10#${1:?номер урока}))")
case "$N" in
  03|04) PROFILE=bi;      SERVICES="metabase" ;;
  17|18) PROFILE=kafka;   SERVICES="kafka connect kafka-ui" ;;
  19)    PROFILE=gp;      SERVICES="greenplum pgweb-gp" ;;
  22|23|24) PROFILE=lake; SERVICES="minio spark trino" ;;
  25)    PROFILE=airflow; SERVICES="airflow" ;;
  *)     PROFILE="";      SERVICES="" ;;
esac
HEAVY="metabase kafka connect kafka-ui greenplum pgweb-gp minio spark trino airflow"
stop=""
for s in $HEAVY; do [[ " $SERVICES " == *" $s "* ]] || stop+=" $s"; done
docker compose --profile bi --profile kafka --profile gp --profile lake --profile airflow stop $stop >/dev/null 2>&1 || true
up() {  # поднять сервисы и дождаться их готовности; подробный журнал — только при ошибке
  local log; log=$(mktemp)
  if ! docker compose "$@" >"$log" 2>&1; then cat "$log"; rm -f "$log"; exit 1; fi
  rm -f "$log"
}
echo "== Урок $N: базовые сервисы"
up up -d --wait postgres clickhouse pgweb pgweb-dwh
if [ -n "$PROFILE" ]; then
  echo "== Урок $N: сервисы профиля $PROFILE (первый запуск скачивает образы, это несколько минут)"
  up --profile "$PROFILE" up -d --wait $SERVICES
  if [ "$PROFILE" = lake ]; then up --profile lake run --rm minio-init; fi
  if [ "$PROFILE" = bi ]; then bash infra/metabase-setup.sh; fi
  if [ "$PROFILE" = airflow ]; then
    # standalone придумывает пароль сам; для курса задаём учебный admin / admin
    docker compose --profile airflow exec -T airflow airflow users reset-password -u admin -p admin >/dev/null 2>&1 \
      || docker compose --profile airflow exec -T airflow airflow users create -u admin -p admin -r Admin -f Учебный -l Стенд -e admin@example.com >/dev/null
  fi
fi
if [ -x "lessons/L$N/setup.sh" ]; then
  echo "== Урок $N: данные урока"
  "lessons/L$N/setup.sh"
fi
echo "== Работают:"
docker compose --profile bi --profile kafka --profile gp --profile lake --profile airflow ps --format '   {{.Service}}  {{.Status}}'
bash infra/ports.sh "$PROFILE"
