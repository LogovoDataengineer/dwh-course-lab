"""Урок 15: инкремент по watermark под живой нагрузкой — ваш скрипт с окном перекрытия не теряет строк."""
from check import ok, pg, safe

SCRIPT = "practice/L15/load_orders.sql"


def q(sql):
    return pg(sql, db="dwh")


def check():
    runs = safe(q, "SELECT run_id, script, seconds, missed FROM inc.runs ORDER BY run_id", default=None)
    ok(runs is not None, "в хранилище есть схема inc урока", "поднимите стенд урока: make lesson-15")
    if runs is None:
        return
    naive = [r for r in runs if r[1] == "lessons/L15/load_naive.sql"]
    ok(bool(naive), f"прогон наивной загрузки под нагрузкой выполнен (прогонов: {len(naive)})",
       "шаг 3: bash lessons/L15/run.sh lessons/L15/load_naive.sql 40")
    mine = [r for r in runs if r[1] == SCRIPT and int(r[2]) >= 30]
    ok(bool(mine), "ваш скрипт прогнан под нагрузкой не меньше 30 секунд",
       f"шаг 6: bash lessons/L15/run.sh {SCRIPT} 40")
    if not mine:
        return
    run_id, _, _, missed = mine[-1]
    ok(missed == "0", f"после прогона {run_id} ODS совпадает с источником (расходится строк: {missed})",
       "окно перекрытия должно быть больше самой длинной транзакции приложения (до 5 секунд)")
    avg, mx, total = q(f"""SELECT round(avg(rows_read)), max(rows_read), (SELECT count(*) FROM inc.src_orders)
                          FROM inc.load_log WHERE run_id = {run_id}""")[0]
    ok(int(mx) < int(total) // 10, f"загрузка осталась инкрементальной: читает в среднем {avg} строк, максимум {mx} из {total}",
       "не забирайте всю таблицу: окно — минуты, а не дни")
    back = q(f"""SELECT count(*) FROM inc.load_log WHERE run_id = {run_id} AND watermark_after < watermark_before""")[0][0]
    ok(back == "0", "отметка не отступает назад между загрузками",
       "новая отметка — greatest(старая, max(updated_at) прочитанных строк)")
