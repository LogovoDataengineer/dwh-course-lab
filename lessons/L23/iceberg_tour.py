"""Урок 23, теория: таблица Iceberg в MinIO — снимки, MERGE, time travel, эволюция схемы и партиций, метаданные, уплотнение."""
from pyspark.sql import SparkSession

# Запуск: make spark F=lessons/L23/iceberg_tour.py
spark = SparkSession.builder.appName("l23-iceberg").config("spark.sql.shuffle.partitions", "4").getOrCreate()
spark.sparkContext.setLogLevel("ERROR")

def show(title, sql, n=20):
    print(f"--- {title}\n> {sql.strip()}")
    spark.sql(sql).show(n, truncate=False)

spark.sql("CREATE NAMESPACE IF NOT EXISTS lake.demo")
spark.sql("DROP TABLE IF EXISTS lake.demo.orders PURGE")
show("создание", """
CREATE TABLE lake.demo.orders (order_id INT, customer_id INT, status STRING, amount DECIMAL(10,2), created_at TIMESTAMP)
USING iceberg PARTITIONED BY (days(created_at))""")
spark.sql("""INSERT INTO lake.demo.orders VALUES
 (1, 3, 'created', 1190.00, TIMESTAMP '2026-03-01 10:00:00'),
 (2, 5, 'paid',     890.00, TIMESTAMP '2026-03-01 11:30:00'),
 (3, 7, 'paid',    6490.00, TIMESTAMP '2026-03-02 09:15:00')""")
spark.sql("""CREATE OR REPLACE TEMP VIEW changes AS SELECT * FROM VALUES
 (1, 3, 'paid',      1190.00, TIMESTAMP '2026-03-01 10:00:00', 'u'),
 (3, 7, 'delivered', 6490.00, TIMESTAMP '2026-03-02 09:15:00', 'u'),
 (2, 5, 'paid',       890.00, TIMESTAMP '2026-03-01 11:30:00', 'd'),
 (4, 2, 'created',    450.00, TIMESTAMP '2026-03-03 14:00:00', 'c')
 AS t(order_id, customer_id, status, amount, created_at, op)""")
show("MERGE", """
MERGE INTO lake.demo.orders o
USING changes c ON o.order_id = c.order_id
WHEN MATCHED AND c.op = 'd' THEN DELETE
WHEN MATCHED THEN UPDATE SET status = c.status, amount = c.amount
WHEN NOT MATCHED AND c.op <> 'd' THEN INSERT (order_id, customer_id, status, amount, created_at)
  VALUES (c.order_id, c.customer_id, c.status, c.amount, c.created_at)""")
show("таблица", "SELECT order_id, status, amount, created_at FROM lake.demo.orders ORDER BY order_id")
show("снимки", "SELECT snapshot_id, operation, summary['added-records'] AS added, summary['deleted-records'] AS deleted, summary['total-records'] AS total FROM lake.demo.orders.snapshots ORDER BY committed_at")
first = spark.sql("SELECT snapshot_id FROM lake.demo.orders.snapshots ORDER BY committed_at LIMIT 1").collect()[0][0]
show("time travel", f"SELECT order_id, status FROM lake.demo.orders VERSION AS OF {first} ORDER BY order_id")
show("файлы данных", "SELECT file_path, record_count FROM lake.demo.orders.files")
show("эволюция схемы", "ALTER TABLE lake.demo.orders ADD COLUMN promo_code STRING")
spark.sql("INSERT INTO lake.demo.orders VALUES (5, 9, 'paid', 300.00, TIMESTAMP '2026-03-03 18:00:00', 'SPRING')")
show("после эволюции", "SELECT order_id, status, promo_code FROM lake.demo.orders ORDER BY order_id")
show("эволюция партиций", "ALTER TABLE lake.demo.orders REPLACE PARTITION FIELD days(created_at) WITH months(created_at)")
spark.sql("INSERT INTO lake.demo.orders VALUES (6, 1, 'created', 990.00, TIMESTAMP '2026-04-02 12:00:00', NULL)")
show("спецификации партиций у файлов", "SELECT spec_id, partition, record_count FROM lake.demo.orders.files ORDER BY spec_id")
show("файлы до уплотнения", "SELECT count(*) AS files FROM lake.demo.orders.files")
show("уплотнение", "CALL lake.system.rewrite_data_files(table => 'demo.orders', options => map('min-input-files', '2'))")
show("удаление старых снимков", "CALL lake.system.expire_snapshots(table => 'demo.orders', older_than => TIMESTAMP '{now}', retain_last => 1)".format(now=__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')))
show("снимки после", "SELECT snapshot_id, operation FROM lake.demo.orders.snapshots ORDER BY committed_at")
# Файлы метаданных таблицы в S3
fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(spark._jvm.java.net.URI("s3a://lake"), spark._jsc.hadoopConfiguration())
print("--- метаданные в S3")
for st in fs.listStatus(spark._jvm.org.apache.hadoop.fs.Path("s3a://lake/iceberg/demo/orders/metadata")):
    print(st.getPath().getName(), st.getLen())

# Merge-on-read: удаление пишет файл удалений, а не переписывает данные
spark.sql("DROP TABLE IF EXISTS lake.demo.orders_mor PURGE")
spark.sql("""CREATE TABLE lake.demo.orders_mor (order_id INT, status STRING) USING iceberg
 TBLPROPERTIES ('format-version' = '2', 'write.delete.mode' = 'merge-on-read', 'write.update.mode' = 'merge-on-read', 'write.merge.mode' = 'merge-on-read')""")
spark.sql("INSERT INTO lake.demo.orders_mor SELECT id, 'paid' FROM range(1, 1001)")
spark.sql("DELETE FROM lake.demo.orders_mor WHERE order_id <= 10")
show("merge-on-read: файлы", "SELECT content, file_format, record_count FROM lake.demo.orders_mor.files")
spark.stop()
