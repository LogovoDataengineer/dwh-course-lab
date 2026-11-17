SHELL := /bin/bash
.PHONY: up down status token check
up:
	@test -s .env || (umask 077; python3 -c "import secrets; print('SPARK_LAB_TOKEN=' + secrets.token_hex(24))" > .env)
	docker compose up -d --build --wait
	@echo 'Готово: 8888 JupyterLab | 8080 Spark Master | 4040 Spark UI | 18080 History Server'
	@echo 'Откройте 8888 через Ports, токен входа: make -C spark-lab token. Порты оставляйте Private.'
status:
	docker compose ps
token:
	@sed -n 's/^SPARK_LAB_TOKEN=//p' .env
check:
	docker compose exec -T notebook python3 check.py
down:
	docker compose down
	@echo 'Контейнеры остановлены; ноутбук, результаты и event logs сохранены. Теперь Stop Current Codespace.'
