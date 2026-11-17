"""Урок 23: НОВАЯ ВЕРСИЯ задания загрузки дня. Разработчик «поправил» обработку сумм — и выкатил ошибку.
Запуск: make spark F="lessons/L23/merge_day_v2.py 2026-03-04" """
import sys
from pyspark.sql import SparkSession

day = sys.argv[1]
spark = SparkSession.builder.appName(f"l23-merge-{day}").config("spark.sql.shuffle.partitions", "4").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
spark.read.parquet(f"s3a://lake/l23/changes/day={day}").createOrReplaceTempView("changes")
spark.sql("""
MERGE INTO lake.shop.orders o
USING changes c ON o.order_id = c.order_id
WHEN MATCHED AND c.op = 'd' THEN DELETE
WHEN MATCHED THEN UPDATE SET status = c.status, amount = o.amount * 100, updated_at = c.updated_at
WHEN NOT MATCHED AND c.op = 'c' THEN INSERT (order_id, customer_id, status, amount, created_at, updated_at)
  VALUES (c.order_id, c.customer_id, c.status, c.amount * 100, c.created_at, c.updated_at)""")
s = spark.sql("SELECT snapshot_id, summary['added-records'] AS added, summary['deleted-records'] AS deleted, summary['total-records'] AS total "
              "FROM lake.shop.orders.snapshots ORDER BY committed_at DESC LIMIT 1").collect()[0]
print(f"{day}: снимок {s.snapshot_id}, записано строк {s.added}, удалено строк {s.deleted}, в таблице {s.total}")
spark.stop()
