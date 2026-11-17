# Команды стенда курса «DWH для дата-инженеров». Список: make help
SHELL := /bin/bash
COMPOSE := docker compose
ALL_PROFILES := --profile bi --profile kafka --profile gp --profile lake --profile airflow --profile tools

.PHONY: help up status psql ch gp trino spark dbt down reset
help:
	@echo 'make up              — базовый стенд: PostgreSQL, ClickHouse, веб-консоль pgweb'
	@echo 'make lesson-17       — поднять всё, что нужно уроку 17 (номер урока из курса)'
	@echo 'make check-17        — проверить практику урока 17 на стенде'
	@echo 'make psql | make ch  — консоль PostgreSQL | ClickHouse'
	@echo 'make ch F=lessons/L02/codecs.sql — выполнить файл SQL в ClickHouse (make psql F=... — в PostgreSQL)'
	@echo 'make gp | make trino — консоль Greenplum | Trino (после make lesson-19 | lesson-24)'
	@echo 'make spark F=lessons/L22/formats.py — запустить задание Spark'
	@echo 'make dbt ARGS="run"  — команда dbt в проекте dbt/shop'
	@echo 'make status          — какие сервисы работают и сколько памяти занимают'
	@echo 'make down            — остановить всё (данные сохраняются)'
	@echo 'make reset CONFIRM=yes — удалить данные стенда и начать заново'

up:
	$(COMPOSE) up -d --wait postgres clickhouse pgweb pgweb-dwh
	@bash infra/ports.sh base

lesson-%:
	@bash infra/lesson.sh $*

check-%:
	@python3 checks/check.py $*

status:
	@$(COMPOSE) $(ALL_PROFILES) ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
	@docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}'

# make psql — консоль; make psql F=файл.sql — выполнить файл; make psql Q="SELECT 1" — один запрос
psql:
ifdef F
	@$(COMPOSE) exec -T postgres psql -U dwh -d $(or $(DB),shop) -v ON_ERROR_STOP=1 -f /lab/$(F)
else
	@$(COMPOSE) exec postgres psql -U dwh -d $(or $(DB),shop) $(if $(Q),-c "$(Q)",)
endif

# make ch — консоль; make ch F=файл.sql — выполнить файл (время каждого запроса — с T=1); make ch Q="SELECT 1"
ch:
ifdef F
	@$(COMPOSE) exec -T clickhouse clickhouse-client --user dwh --password dwh --multiquery --format PrettyCompactMonoBlock $(if $(T),--time,) < $(F)
else
	@$(COMPOSE) exec clickhouse clickhouse-client --user dwh --password dwh $(if $(Q),--format PrettyCompactMonoBlock -q "$(Q)",)
endif

# make gp — консоль Greenplum; make gp F=файл.sql — выполнить файл; make gp Q="SELECT 1"
gp:
ifdef F
	@$(COMPOSE) exec -T greenplum su - gpadmin -c 'psql -d shop -v ON_ERROR_STOP=1 -f /lab/$(F)'
else ifdef Q
	@printf '%s\n' "$$Q" | $(COMPOSE) exec -T greenplum su - gpadmin -c 'psql -d shop'
else
	@$(COMPOSE) exec greenplum su - gpadmin -c 'psql -d shop'
endif

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
