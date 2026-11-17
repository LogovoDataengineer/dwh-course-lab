# Стенд курса «DWH для дата-инженеров»

Учебный стенд для практики курса: настоящие PostgreSQL, ClickHouse, Kafka с Debezium, Greenplum, MinIO (S3), Spark с Iceberg и Delta Lake, Trino, Airflow и dbt. Работает в GitHub Codespaces (машина 4-core, 16 ГБ) или на своём компьютере с Docker.

## Как начать

1. Нажмите **Use this template → Create a new repository**, видимость **Private**.
2. В своём репозитории: **Code → Codespaces → … → New with options**, **Machine type: 4-core**, **Create codespace**.
3. Дождитесь окончания настройки: она сама выполнит `make up` и поднимет PostgreSQL, ClickHouse и веб-консоль pgweb.

На своём компьютере нужны Docker с Compose, Git и Make: `git clone`, затем `make up`.

## Команды

```sh
make up          # базовый стенд: PostgreSQL (5432), ClickHouse (8123), pgweb (8085 и 8086)
make lesson-17   # поднять всё, что нужно уроку 17, и подготовить его данные
make check-17    # проверить практику урока 17
make psql        # консоль PostgreSQL, база shop (магазин «Полка»)
make ch          # консоль ClickHouse
make status      # что запущено и сколько памяти занимает
make down        # остановить стенд (данные сохраняются)
make reset CONFIRM=yes  # удалить данные и начать заново
```

Тяжёлые сервисы включаются только в своих уроках: Kafka — 17–18, Greenplum — 19, MinIO, Spark и Trino — 22–24, Airflow — 25, dbt — 26–27. `make lesson-NN` останавливает сервисы других уроков, чтобы хватало памяти.

| Порт | Что открывается |
|---|---|
| 8085 | pgweb: база сайта `shop` |
| 8086 | pgweb: база хранилища `dwh` |
| 8123 | ClickHouse, веб-консоль по адресу `/play` (пользователь и пароль `dwh`) |
| 8080 | Kafka UI |
| 9001 | MinIO Console (`dwhadmin` / `dwh-admin-123`) |
| 8090 | Trino UI |
| 4040 | Spark UI, пока идёт задание |
| 8088 | Airflow (`admin` / `admin`) |
| 8089 | документация dbt |

Пароли учебные: стенд работает только внутри вашего Codespace. Закончили занятие — остановите Codespace, чтобы не тратить бесплатные часы GitHub.

## Где что лежит

- `lessons/LNN/` — файлы практики урока: SQL, скрипты, задания Spark, DAG, модели dbt.
- `practice/` — ваши решения; `make check-NN` проверяет их на стенде.
- `data/` — рабочая база магазина «Полка» и учебные наборы.
- `infra/` — настройки сервисов, `compose.yaml` — описание стенда.
