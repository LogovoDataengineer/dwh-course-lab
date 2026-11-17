#!/usr/bin/env bash
# Подсказка, какие строки вкладки Ports в VS Code открыть.
echo
echo 'Готово. Веб-интерфейсы — вкладка Ports в VS Code, значок глобуса в строке:'
echo '  8085  PostgreSQL — pgweb        8123  ClickHouse (адрес /play, пользователь и пароль dwh)'
case "${1:-}" in
  bi)      echo '  3000  Metabase (admin@dwh.local / dwh-admin-123)' ;;
  kafka)   echo '  8080  Kafka UI                  8083  Kafka Connect REST' ;;
  gp)      echo '  5433  Greenplum (консоль: make gp)' ;;
  lake)    echo '  9001  MinIO Console (dwhadmin / dwh-admin-123)   8090  Trino UI (любое имя)   4040  Spark UI (пока идёт задание)' ;;
  airflow) echo '  8088  Airflow (admin / admin)' ;;
esac
