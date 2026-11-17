"""Урок 22: посадочная зона озера. Приложение раз в час выгружает события сайта в MinIO: JSON-строки в gzip,
отдельный файл на каждый час, папки event_date=.../hour=... — 14 дней, 5 миллионов событий, 336 файлов."""
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("l22-land").config("spark.sql.shuffle.partitions", "8").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
events = (spark.range(5_000_000)
          .withColumn("ts", F.expr("timestamp'2026-03-01 00:00:00' + make_interval(0, 0, 0, 0, 0, 0, id * 14 * 86400 / 5000000)"))
          .withColumn("event_date", F.expr("date_format(ts, 'yyyy-MM-dd')"))
          .withColumn("hour", F.expr("date_format(ts, 'HH')"))
          .withColumn("user_id", (F.col("id") * 7919 % 200000).cast("int"))
          .withColumn("city", F.expr("element_at(array('Москва','Казань','Екатеринбург','Новосибирск','Самара'), cast(floor(id / 7) % 5 + 1 as int))"))
          .withColumn("event_type", F.expr("element_at(array('view','view','view','click','purchase'), cast(id * 17 % 5 + 1 as int))"))
          .withColumn("amount", F.expr("CASE WHEN id * 17 % 5 = 4 THEN cast(100 + id % 5000 as string) ELSE NULL END"))
          .withColumn("event_time", F.expr("date_format(ts, \"yyyy-MM-dd'T'HH:mm:ss\")"))
          .withColumnRenamed("id", "event_id")
          .drop("ts"))
(events.repartition("event_date", "hour")
       .write.mode("overwrite").option("compression", "gzip")
       .partitionBy("event_date", "hour").json("s3a://lake/raw/events"))
fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(spark._jvm.java.net.URI("s3a://lake/"), spark._jsc.hadoopConfiguration())
s = fs.getContentSummary(spark._jvm.org.apache.hadoop.fs.Path("s3a://lake/raw/events"))
print(f"raw/events: {s.getFileCount()} файлов, {s.getLength() / 1024 / 1024:.1f} MiB, событий {events.count()}")
spark.stop()
