"""Урок 23, шаг 5 (ваш): откат таблицы lake.shop.orders к последнему хорошему снимку.

Номер снимка передаётся аргументом: make spark F="practice/L23/rollback.py <snapshot_id>"
Какой снимок хороший — найдите в шаге 4 по выручке в каждом снимке (bash lessons/L23/snapshots.sh).
Откат в Iceberg — это процедура каталога: CALL lake.system.rollback_to_snapshot('shop.orders', <snapshot_id>).
Данные при откате не копируются и не удаляются: текущим становится старый снимок, а плохие остаются в истории.
После отката загрузите дни 4 и 5 правильным заданием: bash lessons/L23/load.sh 2026-03-04 2026-03-05
"""
import sys
from pyspark.sql import SparkSession

snapshot_id = int(sys.argv[1])
spark = SparkSession.builder.appName("l23-rollback").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

# ЗАДАНИЕ: вызовите процедуру отката и выведите результат (spark.sql(...).show(truncate=False))

spark.sql("SELECT snapshot_id, committed_at, operation FROM lake.shop.orders.snapshots ORDER BY committed_at").show(truncate=False)
spark.stop()
