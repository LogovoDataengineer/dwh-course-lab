"""Урок 22: озеро — посадочная зона JSON и ваша курируемая зона: Parquet с zstd, по файлу на день, правильные типы."""
from check import ch, ok, safe

S3 = "'dwhadmin', 'dwh-admin-123'"
RAW = f"s3('http://minio:9000/lake/raw/events/*/*/*.json.gz', {S3}, 'JSONEachRow')"
CUR = f"s3('http://minio:9000/lake/curated/events/**.parquet', {S3}, 'Parquet')"
META = f"s3('http://minio:9000/lake/curated/events/**.parquet', {S3}, 'ParquetMetadata')"


def check():
    raw = safe(ch, f"SELECT count(), uniqExact(_path), sum(toDecimal64OrZero(amount, 2)) FROM {RAW}", default=None)
    ok(raw is not None and raw[0][0] == "5000000", f"посадочная зона: {raw[0][0] if raw else 0} событий в {raw[0][1] if raw else 0} файлах JSON",
       "поднимите стенд урока: make lesson-22")
    if raw is None:
        return
    files = safe(ch, f"SELECT _path, num_rows FROM {META}", default=None)
    ok(bool(files), "курируемая зона lake/curated/events создана", "шаг 4: допишите practice/L22/curate.py и запустите make spark F=practice/L22/curate.py")
    if not files:
        return
    paths = [f[0] for f in files]
    ok(all("/event_date=" in p and "/hour=" not in p for p in paths), "партиции — папки по дню event_date=..., без деления на часы",
       "partitionBy(\"event_date\") и без столбца hour")
    days = {}
    for p in paths:
        d = p.split("event_date=")[1].split("/")[0] if "event_date=" in p else "?"
        days[d] = days.get(d, 0) + 1
    ok(len(days) == 14 and max(days.values()) == 1, f"по одному файлу на каждый из {len(days)} дней (файлов всего {len(paths)})",
       "перед записью repartition(\"event_date\") — тогда каждый день пишет одна задача")
    ok(all(p.endswith(".zstd.parquet") for p in paths), "файлы сжаты zstd", "option(\"compression\", \"zstd\")")
    types = dict(ch(f"DESCRIBE {CUR}")[i][:2] for i in range(len(ch(f"DESCRIBE {CUR}"))))
    want = {"event_id": "Int64", "event_time": "DateTime64", "user_id": "Int32", "amount": "Decimal(10, 2)"}
    bad = [k for k, v in want.items() if v not in types.get(k, "")]
    ok(not bad and "hour" not in types, "типы столбцов: event_id bigint, event_time timestamp, user_id int, amount decimal(10,2)" +
       (f" (не так: {', '.join(bad)})" if bad else ""), "приведите типы через cast и to_timestamp, столбец hour уберите")
    cur = ch(f"SELECT count(), sum(toDecimal64OrZero(toString(amount), 2)) FROM {CUR}")[0]
    ok(cur[0] == raw[0][0] and float(cur[1]) == float(raw[0][2]), f"все события на месте: {cur[0]} строк, сумма совпадает с посадочной зоной")
