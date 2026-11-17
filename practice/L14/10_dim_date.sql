-- Урок 14, модель «Полки». Шаг 1: календарь. Генерируется, а не загружается; ключ — число ГГГГММДД.
CREATE TABLE polka.dim_date AS
SELECT to_char(d, 'YYYYMMDD')::integer    AS date_key,
       d::date                            AS full_date,
       extract(isodow FROM d)::integer    AS day_of_week,
       extract(isodow FROM d) IN (6, 7)   AS is_weekend,
       date_trunc('month', d)::date       AS month_start
FROM generate_series(date '2025-10-01', date '2026-12-31', interval '1 day') AS d;
ALTER TABLE polka.dim_date ADD PRIMARY KEY (date_key);
