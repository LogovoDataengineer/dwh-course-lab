"""Урок 22, шаг 4 (ваш): переливка посадочной зоны в курируемую.

Прочитайте сырые события s3a://lake/raw/events (JSON в gzip, папки event_date=.../hour=...) и запишите их
в s3a://lake/curated/events так, чтобы:
  1) формат — Parquet со сжатием zstd (option("compression", "zstd"));
  2) партиции — папки по дню event_date=2026-03-01 и т. д., без деления на часы;
  3) в каждой папке дня — один файл, а не по файлу на час (перед записью repartition по event_date);
  4) типы — правильные: event_time — timestamp, amount — decimal(10,2), event_id — bigint, user_id — int;
     столбец hour в курируемой зоне не нужен.
Spark сам поймёт event_date и hour из имён папок при чтении — это партиционные столбцы.
Запуск: make spark F=practice/L22/curate.py     Проверка: make check-22
"""
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("l22-curate").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

raw = spark.read.json("s3a://lake/raw/events")

# ЗАДАНИЕ: приведите типы, уберите hour, сложите по одному файлу на день и запишите Parquet с zstd
curated = raw

curated.write.mode("overwrite").parquet("s3a://lake/curated/events")
spark.stop()
