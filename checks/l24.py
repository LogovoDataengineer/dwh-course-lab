"""Урок 24: Spark — ночное задание с перекосом и ваша ускоренная версия: результат тот же, время меньше."""
from check import ch, ok, pg, safe

S3 = "'dwhadmin', 'dwh-admin-123', 'Parquet'"


def out(name):
    return f"s3('http://minio:9000/lake/l24/out/{name}/*.parquet', {S3})"


def check():
    n = safe(ch, f"SELECT count() FROM s3('http://minio:9000/lake/l24/events/*.parquet', {S3})", default=None)
    ok(n == [["20000000"]], "в озере 20 миллионов событий урока", "поднимите стенд урока: make lesson-24")
    if n is None:
        return
    runs = safe(lambda: pg("SELECT name, min(seconds) FROM lab.spark_runs GROUP BY name", db="dwh"), default=[])
    runs = {r[0]: float(r[1]) for r in runs}
    ok("baseline" in runs, f"исходное задание запущено ({runs.get('baseline', '—')} с)", "шаг 2: bash lessons/L24/run.sh lessons/L24/job.py baseline")
    ok("fixed" in runs, f"ваше задание запущено ({runs.get('fixed', '—')} с)", "шаг 4: bash lessons/L24/run.sh practice/L24/job_fixed.py fixed")
    if "baseline" not in runs or "fixed" not in runs:
        return
    diff = safe(ch, f"""SELECT (SELECT count() FROM (SELECT * FROM {out('fixed')} EXCEPT SELECT * FROM {out('baseline')})) +
                               (SELECT count() FROM (SELECT * FROM {out('baseline')} EXCEPT SELECT * FROM {out('fixed')}))""", default=[["?"]])[0][0]
    ok(diff == "0", f"результат совпадает с исходным заданием (расходится строк: {diff})", "считайте то же самое: соединение, группировка, сумма")
    ok(runs["fixed"] < runs["baseline"] * 0.85, f"задание стало быстрее: {runs['fixed']} с против {runs['baseline']} с",
       "уберите перекос в соединении: broadcast маленькой таблицы, AQE или соление; запустите задание ещё раз")
