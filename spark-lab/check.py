"""Checks the real standalone worker, Python tasks and persisted History Server events."""
import json
import time
import urllib.request
from pathlib import Path
from pyspark.sql import SparkSession

def fetch(url):
    return json.load(urllib.request.urlopen(url, timeout=10))

cluster = fetch("http://spark-master:8080/json/")
assert any(w["state"] == "ALIVE" for w in cluster["workers"]), cluster
spark = SparkSession.builder.appName("Spark lab — проверка окружения").getOrCreate()
spark.sparkContext.setLogLevel("WARN")
app_id = spark.sparkContext.applicationId
assert spark.sparkContext.master == "spark://spark-master:7077"
assert spark.sparkContext.parallelize(range(100), 4).map(lambda x: x * x).sum() == 328350
assert spark.range(10000).repartition(8).count() == 10000
spark_version = spark.version
spark.stop()
for _ in range(30):
    apps = fetch("http://history:18080/api/v1/applications")
    match = next((a for a in apps if a["id"] == app_id), None)
    if match and match["attempts"][0]["completed"]:
        break
    time.sleep(2)
else:
    raise AssertionError(f"History Server has no completed application {app_id}")
report = {"spark": spark_version, "master": "spark://spark-master:7077", "worker_alive": True,
          "python_worker_tasks": "passed", "shuffle_count": 10000, "application_id": app_id,
          "history_completed": True, "event_logs": [f.name for f in Path('/opt/spark-events').iterdir()]}
Path("verification.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
print(json.dumps(report, ensure_ascii=False, indent=2))
