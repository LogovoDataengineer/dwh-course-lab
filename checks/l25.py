"""Урок 25: Airflow — ваш DAG daily_revenue: логическая дата, идемпотентная загрузка дня, проверка, catchup и перезапуск."""
import base64, json, re, urllib.request
from pathlib import Path
from check import ok, pg, safe

API = "http://localhost:8088/api/v1"
DAG_FILE = Path(__file__).resolve().parents[1] / "airflow" / "dags" / "daily_revenue.py"


def api(path):
    req = urllib.request.Request(API + path, headers={"Authorization": "Basic " + base64.b64encode(b"admin:admin").decode()})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)


def check():
    health = safe(api, "/health", default=None)
    ok(health is not None and health["scheduler"]["status"] == "healthy", "Airflow работает, планировщик жив", "поднимите стенд урока: make lesson-25")
    if health is None:
        return
    errs = [e for e in api("/importErrors")["import_errors"] if "daily_revenue" in e["filename"]]
    ok(not errs, "файл airflow/dags/daily_revenue.py разбирается без ошибок",
       (errs[0]["stack_trace"].strip().splitlines()[-1] if errs else ""))
    src = DAG_FILE.read_text()
    src = re.sub(r'^"""[\s\S]*?"""', "", src)          # без описания в начале файла
    src = "\n".join(l.split("#")[0] for l in src.splitlines())   # без комментариев
    ok(not re.search(r"date\.today\(\)|datetime\.now\(\)|datetime\.today\(\)", src) and re.search(r"\{\{\s*(ds|data_interval_start|data_interval_end|logical_date)", src),
       "день загрузки берётся из логической даты ({{ ds }}), а не из часов машины", "шаг 3: используйте шаблон {{ ds }} в SQL")
    tasks = safe(api, "/dags/daily_revenue/tasks", default={"tasks": []})["tasks"]
    ok(any(t["operator_name"] == "SQLCheckOperator" for t in tasks), "в DAG есть проверка SQLCheckOperator после загрузки",
       "добавьте задачу check_day: load_day >> check_day")
    runs = safe(api, "/dags/daily_revenue/dagRuns?limit=100", default={"dag_runs": []})["dag_runs"]
    done = {r["logical_date"][:10] for r in runs if r["state"] == "success"}
    ok(len(done) >= 14, f"DAG догнал все дни с 1 по 14 марта (успешных дней: {len(done)})", "catchup=True и снимите DAG с паузы")
    retried = False
    for r in runs:
        tis = safe(api, f"/dags/daily_revenue/dagRuns/{r['dag_run_id']}/taskInstances", default={"task_instances": []})["task_instances"]
        retried = retried or any(t["try_number"] >= 2 and t["state"] == "success" for t in tis)
    ok(retried, "хотя бы один день перезапущен (Clear) и снова прошёл успешно",
       "шаг 4: в веб-интерфейсе откройте запуск за 5 марта и нажмите Clear, или: airflow tasks clear daily_revenue -s 2026-03-05 -e 2026-03-05 -y")
    diff = pg("""SELECT count(*) FROM (
                   SELECT day, city, orders, revenue FROM af.daily_revenue
                   EXCEPT SELECT created_at::date, city, count(*)::int, sum(amount) FROM af.src_orders GROUP BY 1, 2) x""", db="dwh")[0][0]
    rows = pg("SELECT count(*), count(DISTINCT (day, city)) FROM af.daily_revenue", db="dwh")[0]
    ok(diff == "0" and rows[0] == rows[1] and rows[0] != "0", f"витрина совпадает с источником, без дублей (строк {rows[0]}, расхождений {diff})",
       "загрузка дня должна сначала удалять день: DELETE ... WHERE day = '{{ ds }}'")
