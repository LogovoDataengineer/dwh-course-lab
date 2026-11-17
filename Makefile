# Команды стенда курса «DWH для дата-инженеров». Список: make help
SHELL := /bin/bash
COMPOSE := docker compose
ALL_PROFILES := --profile kafka --profile gp --profile lake --profile airflow --profile tools

.PHONY: help up status psql ch gp trino spark dbt down reset
help:
	@echo 'make up              — базовый стенд: PostgreSQL, ClickHouse, веб-консоль pgweb'
	@echo 'make lesson-17       — поднять всё, что нужно уроку 17 (номер урока из курса)'
	@echo 'make check-17        — проверить практику урока 17 на стенде'
	@echo 'make psql | make ch  — консоль PostgreSQL | ClickHouse'
	@echo 'make gp | make trino — консоль Greenplum | Trino (после make lesson-19 | lesson-24)'
	@echo 'make spark F=lessons/L22/formats.py — запустить задание Spark'
	@echo 'make dbt ARGS="run"  — команда dbt в проекте dbt/shop'
	@echo 'make status          — какие сервисы работают и сколько памяти занимают'
	@echo 'make down            — остановить всё (данные сохраняются)'
	@echo 'make reset CONFIRM=yes — удалить данные стенда и начать заново'

up:
	$(COMPOSE) up -d --wait postgres clickhouse pgweb
	@bash infra/ports.sh base

lesson-%:
	@bash infra/lesson.sh $*

check-%:
	@python3 checks/check.py $*

status:
	@$(COMPOSE) $(ALL_PROFILES) ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
	@docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}'

psql:
	$(COMPOSE) exec postgres psql -U dwh -d $(or $(DB),shop)

ch:
	$(COMPOSE) exec clickhouse clickhouse-client --user dwh --password dwh $(if $(Q),-q "$(Q)",)

gp:
	$(COMPOSE) exec greenplum su - gpadmin -c 'psql -d shop'

trino:
	$(COMPOSE) exec trino trino $(if $(Q),--execute "$(Q)",)

spark:
	$(COMPOSE) exec spark spark-submit --master 'local[2]' $(F)

dbt:
	$(COMPOSE) run --rm --service-ports dbt $(ARGS)

down:
	$(COMPOSE) $(ALL_PROFILES) down

reset:
	@test "$(CONFIRM)" = yes || (echo 'Удалит все данные стенда. Запустите make reset CONFIRM=yes'; exit 2)
	$(COMPOSE) $(ALL_PROFILES) down --volumes
