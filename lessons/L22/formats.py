"""Урок 22: одни и те же 5 млн событий в CSV, JSON, Avro, Parquet и ORC на MinIO; размеры, скорость и отсечение."""
import time
from pyspark.sql import SparkSession, functions as F

# Запуск: make spark F=lessons/L22/formats.py — пишет около 1 ГБ в MinIO, в конце удаляет за собой.
spark = SparkSession.builder.appName("l22-formats").config("spark.sql.shuffle.partitions", "8").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

events = (spark.range(5_000_000)
          .withColumn("event_date", F.expr("date_add(date'2026-03-01', cast(id % 14 as int))"))
          .withColumn("user_id", (F.col("id") * 7919 % 200000).cast("int"))
          .withColumn("city", F.expr("element_at(array('Москва','Казань','Екатеринбург','Новосибирск','Самара'), cast(id % 5 + 1 as int))"))
          .withColumn("event_type", F.expr("element_at(array('view','view','view','click','purchase'), cast(id % 5 + 1 as int))"))
          .withColumn("amount", F.expr("CASE WHEN id % 5 = 4 THEN cast(100 + id % 5000 as decimal(10,2)) ELSE cast(0 as decimal(10,2)) END"))
          .withColumnRenamed("id", "event_id"))

base = "s3a://lake/l11"
for fmt in ["csv", "json", "avro", "parquet", "orc"]:
    w = events.coalesce(4).write.mode("overwrite")
    if fmt == "csv":
        w = w.option("header", "true")
    t = time.time()
    w.format(fmt).save(f"{base}/{fmt}")
    print(f"write {fmt}: {time.time() - t:.1f} s")

# Размеры каталогов в S3
fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(spark._jvm.java.net.URI(base), spark._jsc.hadoopConfiguration())
for fmt in ["csv", "json", "avro", "parquet", "orc"]:
    s = fs.getContentSummary(spark._jvm.org.apache.hadoop.fs.Path(f"{base}/{fmt}"))
    print(f"size {fmt}: {s.getLength() / 1024 / 1024:.1f} MiB, files {s.getFileCount()}")

# Один запрос ко всем форматам: выручка покупок за 3 дня
schema = events.schema
for fmt in ["csv", "json", "avro", "parquet", "orc"]:
    r = spark.read.format(fmt)
    r = r.option("header", "true").schema(schema) if fmt in ("csv", "json") else r
    df = r.load(f"{base}/{fmt}")
    t = time.time()
    res = (df.where("event_type = 'purchase' AND event_date BETWEEN '2026-03-05' AND '2026-03-07'")
             .agg(F.count("*").alias("n"), F.sum("amount").alias("revenue")).collect()[0])
    print(f"query {fmt}: {time.time() - t:.2f} s -> {res['n']} {res['revenue']}")
fs.delete(spark._jvm.org.apache.hadoop.fs.Path(base), True)
spark.stop()
