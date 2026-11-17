"""Урок 23, теория: таблица Delta Lake в MinIO — журнал _delta_log, история, time travel, OPTIMIZE."""
from pyspark.sql import SparkSession

# Запуск: make spark F=lessons/L23/delta_tour.py
spark = SparkSession.builder.appName("l23-delta").config("spark.sql.shuffle.partitions", "4").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
path = "s3a://lake/delta/orders"

def show(title, sql):
    print(f"--- {title}\n> {sql.strip()}")
    spark.sql(sql).show(20, truncate=False)

fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(spark._jvm.java.net.URI("s3a://lake"), spark._jsc.hadoopConfiguration())
fs.delete(spark._jvm.org.apache.hadoop.fs.Path(path), True)
spark.sql(f"CREATE TABLE delta.`{path}` (order_id INT, status STRING, amount DECIMAL(10,2)) USING delta")
spark.sql(f"INSERT INTO delta.`{path}` VALUES (1, 'created', 1190.00), (2, 'paid', 890.00)")
spark.sql(f"INSERT INTO delta.`{path}` VALUES (3, 'paid', 6490.00)")
spark.sql(f"UPDATE delta.`{path}` SET status = 'paid' WHERE order_id = 1")
show("история", f"DESCRIBE HISTORY delta.`{path}`".replace("DESCRIBE HISTORY", "SELECT version, operation, operationMetrics['numOutputRows'] AS output_rows FROM (DESCRIBE HISTORY") + ") ORDER BY version" if False else f"DESCRIBE HISTORY delta.`{path}`")
show("time travel", f"SELECT * FROM delta.`{path}` VERSION AS OF 1 ORDER BY order_id")
print("--- журнал _delta_log")
for st in fs.listStatus(spark._jvm.org.apache.hadoop.fs.Path(path + "/_delta_log")):
    print(st.getPath().getName(), st.getLen())
log = spark.read.text(path + "/_delta_log/00000000000000000003.json").collect()
print("--- 00000000000000000003.json")
for r in log:
    print(r[0][:220])
show("OPTIMIZE", f"OPTIMIZE delta.`{path}`")
spark.stop()
