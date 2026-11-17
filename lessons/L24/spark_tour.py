"""Урок 24: как Spark выполняет запрос — ленивость, партиции, shuffle, broadcast и sort-merge join, перекос и соление, файлы на выходе.
Запуск: make spark F=lessons/L24/spark_tour.py (данные генерирует сам, пишет в s3a://lake/l24tour)
"""
import sys
import time
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("l24-tour").config("spark.sql.shuffle.partitions", "200").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")


def title(t):
    print(f"\n===== {t}", flush=True)


src = "s3a://lake/l24tour/events"
try:
    events = spark.read.parquet(src)
except Exception:
    gen = (spark.range(10_000_000)
           .withColumn("h", F.abs(F.xxhash64("id")))
           .withColumn("event_date", F.expr("date_add(date'2026-03-01', cast(h % 31 as int))"))
           .withColumn("user_id", (F.col("h") % 500000).cast("int"))
           .withColumn("city", F.expr("element_at(array('Москва','Казань','Екатеринбург','Новосибирск','Самара'), cast(h % 7 % 5 + 1 as int))"))
           .withColumn("event_type", F.expr("element_at(array('view','view','view','click','purchase'), cast(h % 11 % 5 + 1 as int))"))
           .withColumn("amount", F.expr("CASE WHEN h % 11 % 5 = 4 THEN cast(100 + h % 9900 as decimal(10,2)) ELSE cast(0 as decimal(10,2)) END"))
           .withColumnRenamed("id", "event_id").drop("h"))
    gen.repartition(16).write.mode("overwrite").parquet(src)
    events = spark.read.parquet(src)

title("1. ленивость")
t = time.time()
purchases = events.filter("event_type = 'purchase'").select("event_date", "city", "user_id", "amount")
print(f"трансформации: {time.time() - t:.3f} s")
t = time.time()
print("строк:", purchases.count())
print(f"действие count: {time.time() - t:.1f} s")

title("2. партиции и задачи")
print("партиций при чтении:", events.rdd.getNumPartitions())
print("партиций после groupBy:", purchases.groupBy("city").count().rdd.getNumPartitions())

title("3. план агрегации")
agg = purchases.groupBy("city").agg(F.sum("amount").alias("revenue"))
agg.explain("formatted")
agg.orderBy("city").show()

title("4. broadcast join")
cities = spark.sql("SELECT * FROM VALUES ('Москва', 'Центр'), ('Казань', 'Поволжье'), ('Самара', 'Поволжье'), "
                   "('Екатеринбург', 'Урал'), ('Новосибирск', 'Сибирь') AS t(city, region)")
by_region = purchases.join(cities, "city").groupBy("region").agg(F.sum("amount").alias("revenue"))
by_region.explain()
t = time.time(); by_region.orderBy("region").show(); print(f"broadcast: {time.time() - t:.1f} s")

title("5. sort-merge join (broadcast выключен)")
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
spark.conf.set("spark.sql.adaptive.enabled", "false")
by_region2 = purchases.join(cities, "city").groupBy("region").agg(F.sum("amount").alias("revenue"))
by_region2.explain()
t = time.time(); by_region2.collect(); print(f"sort-merge: {time.time() - t:.1f} s")
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", str(10 * 1024 * 1024))
spark.conf.set("spark.sql.adaptive.enabled", "true")

title("6. перекос")
skewed = events.withColumn("seller_id", F.when(F.col("event_id") % 10 < 7, F.lit(1)).otherwise((F.col("event_id") % 1000).cast("int")))
spark.conf.set("spark.sql.adaptive.enabled", "false")
parts = (skewed.repartition(8, "seller_id").groupBy(F.spark_partition_id().alias("partition")).count()
         .orderBy("partition"))
parts.show()
title("7. соление")
salted = skewed.withColumn("salt", (F.col("event_id") % 64).cast("int"))
parts2 = (salted.repartition(8, "seller_id", "salt").groupBy(F.spark_partition_id().alias("partition")).count()
          .orderBy("partition"))
parts2.show()
two_phase = (salted.groupBy("seller_id", "salt").agg(F.count("*").alias("c"))
             .groupBy("seller_id").agg(F.sum("c").alias("events")).orderBy(F.desc("events")))
two_phase.show(3)
spark.conf.set("spark.sql.adaptive.enabled", "true")

title("8. файлы на выходе")
out = "s3a://lake/l24tour/out"
purchases.write.mode("overwrite").partitionBy("event_date").parquet(f"{out}/many")
purchases.repartition("event_date").write.mode("overwrite").partitionBy("event_date").parquet(f"{out}/few")
for name in ["many", "few"]:
    files = spark.read.parquet(f"{out}/{name}").select(F.input_file_name()).distinct().count()
    print(f"{name}: файлов {files}")

if len(sys.argv) > 1 and sys.argv[1] == "wait":
    print("Spark UI открыт, жду 600 секунд", flush=True)
    time.sleep(600)
spark.stop()
