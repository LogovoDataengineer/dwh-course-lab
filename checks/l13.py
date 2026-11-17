"""Урок 13: факт поездок в ClickHouse в зерне поездки (без размножения оплат) и своя витрина taxi.city_day из аддитивных мер."""
from check import ch, ok, pg, safe

COLS = ["trip_date", "city", "car_class", "trips", "revenue", "distance_km", "bonus_amount"]
REF = """SELECT trip_date, city, car_class, count() AS trips, sum(price) AS revenue, sum(distance_km) AS distance_km,
                sum(bonus_amount) AS bonus_amount
         FROM taxi.fact_trips WHERE status = 'completed' GROUP BY trip_date, city, car_class"""


def check():
    fact = safe(ch, "SELECT count(), sum(price), sum(bonus_amount) FROM taxi.fact_trips", default=None)
    ok(fact is not None, "в ClickHouse есть факт taxi.fact_trips", "шаг 4: make psql F=lessons/L13/model.sql, затем make ch F=lessons/L13/to_clickhouse.sql")
    if fact is None:
        return
    src = pg("""SELECT count(*), sum(price), (SELECT sum(amount) FROM taxi.trip_payments WHERE method = 'bonus') FROM taxi.trips""")[0]
    ok(int(fact[0][0]) == int(src[0]), f"в факте по строке на поездку: {fact[0][0]} из {src[0]}")
    ok(float(fact[0][1]) == float(src[1]) and float(fact[0][2]) == float(src[2]),
       "сумма цен и бонусов в факте совпадает с источником: оплаты не размножили поездки")
    cols = [r[0] for r in safe(ch, "SELECT name FROM system.columns WHERE database = 'taxi' AND table = 'city_day' ORDER BY position", default=[])]
    ok(bool(cols), "вы создали витрину taxi.city_day", "шаг 7: допишите practice/L13/city_day.sql и выполните make ch F=practice/L13/city_day.sql")
    if not cols:
        return
    ok(cols == COLS, f"столбцы {', '.join(COLS)} (сейчас: {', '.join(cols)})", "переименуйте столбцы через AS, порядок важен; средних и отношений в витрине нет")
    if cols != COLS:
        return
    tot = ch("SELECT sum(trips), sum(revenue), sum(bonus_amount) FROM taxi.city_day")[0]
    ref = ch("SELECT count(), sum(price), sum(bonus_amount) FROM taxi.fact_trips WHERE status = 'completed'")[0]
    ok(int(tot[0]) == int(ref[0]), f"в витрине только завершённые поездки: {tot[0]} из {ref[0]}", "status = 'completed'")
    ok(float(tot[1]) == float(ref[1]) and float(tot[2]) == float(ref[2]), "общая выручка и бонусы витрины совпадают с фактом")
    diff = ch(f"SELECT count() FROM (SELECT * FROM taxi.city_day EXCEPT {REF})")[0][0]
    rows = ch(f"SELECT (SELECT count() FROM taxi.city_day), (SELECT count() FROM ({REF}))")[0]
    ok(diff == "0" and rows[0] == rows[1], f"строки витрины совпадают с эталоном по дню, городу и классу (строк {rows[0]} из {rows[1]}, расхождений {diff})",
       "зерно витрины — день, город, класс автомобиля в момент поездки")
