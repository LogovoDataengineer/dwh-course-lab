"""Урок 2: версии таблицы с кодеками и с другой сортировкой, своя компактная таблица меньше 50 МиБ."""
from check import ch, ok, safe

MIB = 1024 * 1024


def size(table):
    r = safe(ch, f"SELECT sum(data_compressed_bytes), count() FROM system.columns WHERE database = 'dwh' AND table = '{table}'", default=[["0", "0"]])
    return int(r[0][0] or 0), int(r[0][1])


def check():
    base_rows, base_rev = ch("SELECT count(), sum(quantity * price) FROM dwh.sales_history")[0]
    for t, step in (("sales_codecs", "шаг 3, lessons/L02/codecs.sql"), ("sales_by_city", "шаг 4, lessons/L02/sorted.sql")):
        ok(size(t)[1] > 0, f"есть таблица dwh.{t}", f"выполните {step}")
    b, cols = size("sales_compact")
    ok(cols > 0, "вы создали свою таблицу dwh.sales_compact", "шаг 6: создайте таблицу и скопируйте в неё dwh.sales_history")
    if cols:
        rows, rev = ch("SELECT count(), sum(quantity * price) FROM dwh.sales_compact")[0]
        ok(rows == base_rows, f"в ней все строки истории ({rows})", "скопируйте данные: INSERT INTO dwh.sales_compact SELECT * FROM dwh.sales_history")
        ok(float(rev) == float(base_rev), "выручка совпадает с исходной таблицей", "проверьте типы: Decimal не должен терять копейки")
        parts = int(ch("SELECT count() FROM system.parts WHERE database = 'dwh' AND table = 'sales_compact' AND active")[0][0])
        ok(b < 50 * MIB, f"на диске {b / MIB:.1f} МиБ — меньше 50 МиБ (исходная таблица — {size('sales_history')[0] / MIB:.1f} МиБ)",
           "добавьте кодеки Delta к растущим столбцам и ZSTD к остальным; после вставки выполните OPTIMIZE TABLE dwh.sales_compact FINAL")
        ok(parts == 1, f"таблица слита в один кусок (кусков: {parts})", "выполните OPTIMIZE TABLE dwh.sales_compact FINAL")
