"""Урок 24: ночное задание — сколько событий и выручки по сегментам и городам пользователей за каждый день.
Так его написали год назад: соединение событий с пользователями и группировка. Адаптивное выполнение (AQE)
в кластере тогда было выключено — оставляем как есть. Результат пишется в s3a://lake/l24/out/<имя задания>."""
import sys, time
from pyspark.sql import SparkSession, functions as F

name = sys.argv[1] if len(sys.argv) > 1 else "job"
hold = int(sys.argv[2]) if len(sys.argv) > 2 else 0   # секунд держать Spark UI открытым после работы
spark = (SparkSession.builder.appName(f"l24-{name}")
         .config("spark.sql.adaptive.enabled", "false")
         .config("spark.sql.shuffle.partitions", "64")
         .config("spark.sql.autoBroadcastJoinThreshold", "10MB")
         .getOrCreate())
spark.sparkContext.setLogLevel("ERROR")
t = time.time()
events = spark.read.parquet("s3a://lake/l24/events")
users = spark.read.parquet("s3a://lake/l24/users")
report = (events.join(users, "user_id")
          .groupBy("event_date", "segment", "city")
          .agg(F.count("*").alias("events"), F.sum("amount").alias("revenue")))
report.write.mode("overwrite").parquet(f"s3a://lake/l24/out/{name}")
print(f"{name}: {time.time() - t:.1f} с", flush=True)
if hold:
    print(f"Spark UI открыт на порту 4040, жду {hold} с", flush=True)
    time.sleep(hold)
spark.stop()
