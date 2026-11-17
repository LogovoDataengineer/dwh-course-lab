"""Урок 23: таблица Iceberg lake.shop.orders — миллион заказов за январь и февраль 2026 года, и изменения
за 1–5 марта в посадочной зоне s3a://lake/l23/changes (по папке на день): новые заказы, смены статусов, удаления.
Заодно считается эталон — какой должна быть таблица после правильной загрузки всех пяти дней."""
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder.appName("l23-setup").config("spark.sql.shuffle.partitions", "4").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")
spark.sql("CREATE NAMESPACE IF NOT EXISTS lake.shop")
spark.sql("DROP TABLE IF EXISTS lake.shop.orders PURGE")
spark.sql("""CREATE TABLE lake.shop.orders (order_id BIGINT, customer_id INT, status STRING, amount DECIMAL(10,2),
             created_at TIMESTAMP, updated_at TIMESTAMP) USING iceberg PARTITIONED BY (months(created_at))""")
base = (spark.range(1, 1_000_001).select(
    F.col("id").alias("order_id"), (F.col("id") * 7919 % 100000 + 1).cast("int").alias("customer_id"),
    F.expr("element_at(array('delivered','delivered','delivered','paid','shipped','cancelled'), cast(id % 6 + 1 as int))").alias("status"),
    F.expr("cast(300 + id * 37 % 9000 as decimal(10,2))").alias("amount"),
    F.expr("timestamp'2026-01-01 00:00:00' + make_interval(0, 0, 0, 0, 0, 0, id * 59 * 86400 / 1000000)").alias("created_at")))
base = base.withColumn("updated_at", F.col("created_at"))
base.writeTo("lake.shop.orders").append()

changes = []
for d in range(1, 6):
    day = f"2026-03-0{d}"
    ts = F.expr(f"timestamp'{day} 12:00:00'")
    upd = (spark.range(d * 150_000, d * 150_000 + 50_000).select(F.col("id").alias("order_id"))
           .withColumn("op", F.lit("u")).withColumn("status", F.lit("delivered")))
    dele = spark.range(d * 7_000, d * 7_000 + 1_000).select(F.col("id").alias("order_id")).withColumn("op", F.lit("d")).withColumn("status", F.lit(None).cast("string"))
    new = (spark.range(1_000_000 + (d - 1) * 20_000 + 1, 1_000_000 + d * 20_000 + 1).select(F.col("id").alias("order_id"))
           .withColumn("op", F.lit("c")).withColumn("status", F.lit("created")))
    ch = (upd.unionByName(dele).unionByName(new)
          .withColumn("customer_id", (F.col("order_id") * 7919 % 100000 + 1).cast("int"))
          .withColumn("amount", F.expr("cast(300 + order_id * 37 % 9000 as decimal(10,2))"))
          .withColumn("created_at", F.when(F.col("op") == "c", ts).otherwise(F.lit(None).cast("timestamp")))
          .withColumn("updated_at", ts))
    ch.repartition(1).write.mode("overwrite").parquet(f"s3a://lake/l23/changes/day={day}")
    changes.append(ch)

# эталон: последовательное применение всех пяти дней
t = base
for ch in changes:
    keep = t.join(ch.select("order_id"), "order_id", "left_anti")
    changed = (t.join(ch.where("op = 'u'").select("order_id", F.col("status").alias("s2"), F.col("updated_at").alias("u2")), "order_id")
                .withColumn("status", F.col("s2")).withColumn("updated_at", F.col("u2")).drop("s2", "u2"))
    new = ch.where("op = 'c'").select(*base.columns)
    t = keep.unionByName(changed).unionByName(new)
exp = t.groupBy("status").agg(F.count("*").alias("orders"), F.sum("amount").alias("revenue"))
exp.repartition(1).write.mode("overwrite").parquet("s3a://lake/l23/expected")
print("orders:", spark.table("lake.shop.orders").count())
exp.orderBy("status").show()
spark.stop()
