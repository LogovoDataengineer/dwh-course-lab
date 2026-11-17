"""Урок 24: данные для ночного задания — 20 млн событий сайта и 2 млн пользователей в озере (Parquet в MinIO).
Пользователь 777 — бот парсера цен: на него приходится половина всех событий."""
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("l24-setup").config("spark.sql.shuffle.partitions", "16").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
events = (spark.range(20_000_000)
          .withColumn("user_id", F.expr("CASE WHEN id % 2 = 0 THEN 777 ELSE 1 + (id * 7919) % 2000000 END").cast("int"))
          .withColumn("event_date", F.expr("date_add(date'2026-03-01', cast(id % 14 as int))"))
          .withColumn("event_type", F.expr("element_at(array('view','view','view','click','purchase'), cast(id * 17 % 5 + 1 as int))"))
          .withColumn("amount", F.expr("CASE WHEN id * 17 % 5 = 4 THEN cast(100 + id % 5000 as decimal(10,2)) ELSE cast(0 as decimal(10,2)) END"))
          .withColumnRenamed("id", "event_id"))
events.repartition(16).write.mode("overwrite").parquet("s3a://lake/l24/events")
users = (spark.range(1, 2_000_001).withColumnRenamed("id", "user_id")
         .withColumn("user_id", F.col("user_id").cast("int"))
         .withColumn("segment", F.expr("element_at(array('new','regular','vip','bot'), cast(CASE WHEN user_id = 777 THEN 4 ELSE user_id % 3 + 1 END as int))"))
         .withColumn("email", F.expr("concat('user', user_id, '@mail.example')"))
         .withColumn("city", F.expr("element_at(array('Москва','Казань','Екатеринбург','Новосибирск','Самара'), cast(user_id % 5 + 1 as int))")))
users.repartition(4).write.mode("overwrite").parquet("s3a://lake/l24/users")
print("events:", spark.read.parquet("s3a://lake/l24/events").count(), "users:", spark.read.parquet("s3a://lake/l24/users").count())
spark.stop()
