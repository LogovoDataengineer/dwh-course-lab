"""Урок 26: dbt — сборка без ошибок после исправления staging и ваша модель mart_city_revenue с тестами и документацией."""
import json, subprocess
from pathlib import Path
from check import ROOT, ok, pg, safe

TARGET = Path(__file__).resolve().parents[1] / "dbt" / "shop" / "target"
MODEL = "model.dbt_shop.mart_city_revenue"


def load(name):
    return json.loads((TARGET / name).read_text())


def check():
    docs = (TARGET / "catalog.json").exists()
    # проверка сама собирает проект, как CI перед слиянием (около 15 секунд)
    subprocess.run(["docker", "compose", "run", "--rm", "-T", "dbt", "build", "--no-partial-parse"], cwd=ROOT, capture_output=True, text=True)
    rr = safe(load, "run_results.json", default=None)
    ok(rr is not None, "dbt build запустился", "поднимите стенд урока: make lesson-26")
    if rr is None:
        return
    which = rr.get("args", {}).get("which")
    bad = [r["unique_id"].split(".")[2] for r in rr["results"] if r["status"] not in ("success", "pass")]
    ok(which == "build" and not bad, f"dbt build прошёл без ошибок и пропусков (узлов: {len(rr['results'])})" +
       (f"; не прошли: {', '.join(bad[:3])}" if bad else ""), "исправьте модели и запустите make dbt ARGS=\"build\" ещё раз")
    st = safe(pg, "SELECT string_agg(DISTINCT status, ',' ORDER BY status) FROM stg.stg_orders", default=[["—"]])[0][0]
    ok(st == "cancelled,delivered,paid", f"в stg_orders статусы приведены к одному виду ({st})",
       "шаг 4: lower(trim(status)) в models/staging/stg_orders.sql")
    man = safe(load, "manifest.json", default={"nodes": {}})
    node = man["nodes"].get(MODEL)
    ok(node is not None, "в проекте есть модель mart_city_revenue", "шаг 5: создайте models/marts/mart_city_revenue.sql")
    if node is None:
        return
    ok(node["config"]["materialized"] == "table", f"mart_city_revenue — таблица ({node['config']['materialized']})", "витрины в marts — table")
    deps = node["depends_on"]["nodes"]
    ok(deps and all(d.startswith("model.") for d in deps), "модель строится из staging через ref(), а не напрямую из source()",
       "используйте {{ ref('stg_orders') }} и другие staging-модели")
    tests = {n["test_metadata"]["name"] for n in man["nodes"].values()
             if n["resource_type"] == "test" and MODEL in n["depends_on"]["nodes"] and n.get("column_name") == "city" and n.get("test_metadata")}
    ok({"unique", "not_null"} <= tests, f"на столбце city тесты unique и not_null ({', '.join(sorted(tests)) or 'нет'})",
       "опишите модель в models/marts/schema.yml")
    diff = safe(pg, """SELECT (SELECT sum(revenue) FROM cdm.mart_city_revenue) =
                              (SELECT sum(i.quantity * i.price) FROM orders o JOIN order_items i USING (order_id)
                               WHERE lower(trim(o.status)) <> 'cancelled')""", default=[["f"]])[0][0]
    ok(diff == "t", "выручка по городам в сумме равна выручке неотменённых заказов в источнике")
    ok(docs, "документация проекта собрана (dbt docs generate)", "шаг 6: make dbt ARGS=\"docs generate\"")
