# Spark, JupyterLab и History Server в Codespaces

Отдельный учебный стенд: Spark 3.5.6 Standalone (master + worker), JupyterLab с PySpark и History Server. Все сервисы работают на одной виртуальной машине; это учебный кластер, а не несколько физических узлов.

## Запуск

В GitHub: Code → Codespaces → … → New with options. Выберите ветку `feat/spark-notebook-history`, конфигурацию **Spark + Jupyter + History Server**, машину **4-core / 16 GB**. Настройка сама выполнит `make -C spark-lab up`.

При повторном запуске Codespace выполните эту команду снова. Она сохраняет существующий токен, ноутбук и event logs.

| Порт | Назначение |
|---|---|
| 8888 | JupyterLab; откройте `Spark_от_ноутбука_до_истории.ipynb` |
| 8080 | Master UI: зарегистрированный worker, ресурсы и приложения |
| 8081 | Worker UI |
| 4040 | UI текущего приложения, пока существует SparkContext |
| 18080 | History Server: приложения из сохранённых event logs |

Открывайте порты через вкладку Ports, видимость **Private**. Токен Jupyter получите командой `make -C spark-lab token` и вставьте в поле Password or token. Токен не хранится в Git и не должен попадать в видео.

Выполняйте ячейки по очереди (Shift+Enter). После `spark.stop()` текущий UI на 4040 закрывается; завершённое приложение остаётся на 18080. Перед запуском ноутбука после Stop выполните его первую ячейку снова.

## Проверка и остановка

`make -C spark-lab check` проверяет реальный worker, Python-задачи, shuffle и появление завершённого приложения в History Server. Проверку запускайте при остановленном SparkContext ноутбука, чтобы два приложения не делили учебный worker.

`make -C spark-lab down` останавливает контейнеры без удаления томов. Затем выполните **Codespaces: Stop Current Codespace**, чтобы остановить саму виртуальную машину. При следующем запуске `make -C spark-lab up` восстановит сервисы, а event logs останутся в томе `spark-events`.

Исходный DWH-стенд не меняется: этот стенд использует собственный Compose-проект. Одновременно запускать оба стенда не нужно: некоторые порты совпадают.

Официальные источники: [Spark Standalone](https://spark.apache.org/docs/3.5.6/spark-standalone.html), [Spark monitoring и event logs](https://spark.apache.org/docs/3.5.6/monitoring.html), [защита Jupyter Server](https://jupyter-server.readthedocs.io/en/latest/operators/security.html).
