-- Урок 2: сколько данных читают запросы. Метка log_comment помогает найти запрос в журнале system.query_log.
-- q1: три столбца из девяти
SELECT city, sum(quantity * price) FROM dwh.sales_history GROUP BY city SETTINGS log_comment = 'q1' FORMAT Null;
-- q2: все столбцы (выгрузить таблицу целиком)
SELECT * FROM dwh.sales_history SETTINGS log_comment = 'q2' FORMAT Null;
-- q3: фильтр по городу, таблица отсортирована по времени
SELECT count(), sum(quantity * price) FROM dwh.sales_history WHERE city = 'Казань' SETTINGS log_comment = 'q3' FORMAT Null;
-- q4: тот же фильтр, таблица отсортирована по городу
SELECT count(), sum(quantity * price) FROM dwh.sales_by_city WHERE city = 'Казань' SETTINGS log_comment = 'q4' FORMAT Null;
SYSTEM FLUSH LOGS;
SELECT * FROM
(
    SELECT log_comment AS q, read_rows, formatReadableSize(read_bytes) AS read, query_duration_ms AS ms
    FROM system.query_log
    WHERE type = 'QueryFinish' AND log_comment IN ('q1', 'q2', 'q3', 'q4')
    ORDER BY event_time_microseconds DESC
    LIMIT 1 BY log_comment          -- только последний запуск каждого запроса
)
ORDER BY q;
