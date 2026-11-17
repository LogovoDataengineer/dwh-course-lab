"""Урок 24, шаг 4 (ваш): ускорьте ночное задание. Считает то же самое — сколько событий и выручки по сегментам и городам пользователей за каждый день.
Так его написали год назад: соединение событий с пользователями и группировка. Адаптивное выполнение (AQE)
в кластере было выключено. Результат должен совпасть с исходным заданием до строки.
Перекос: пользователь 777 (бот) — половина всех событий, и в соединении все его строки попадают в одну задачу
(шаг 3). Способы, разобранные в теории урока, — выберите один или совместите:
  * broadcast-соединение: из пользователей нужны только user_id, segment и city — такая таблица маленькая,
    её можно разослать всем задачам (F.broadcast), и событиям не придётся перемешиваться по user_id;
  * адаптивное выполнение: spark.sql.adaptive.enabled = true — AQE само делит перекошенную партицию соединения;
  * соление ключа: добавить к user_id случайную «соль» 0..N-1 и размножить пользователей на N копий.
Запуск: bash lessons/L24/run.sh practice/L24/job_fixed.py fixed     Проверка: make check-24"""
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
# ЗАДАНИЕ: перепишите соединение так, чтобы оно не упиралось в одну задачу
report = (events.join(users, "user_id")
          .groupBy("event_date", "segment", "city")
          .agg(F.count("*").alias("events"), F.sum("amount").alias("revenue")))
report.write.mode("overwrite").parquet(f"s3a://lake/l24/out/{name}")
print(f"{name}: {time.time() - t:.1f} с", flush=True)
if hold:
    print(f"Spark UI открыт на порту 4040, жду {hold} с", flush=True)
    time.sleep(hold)
spark.stop()
