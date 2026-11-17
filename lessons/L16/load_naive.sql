-- Урок 16: загрузка дня «как получилось»: дописать продажи дня в факт, затем пересобрать витрину
-- по дням и городам целиком. Переменная day — день загрузки, её ставит chaos.sh.
INSERT INTO rel.fact_sales
SELECT sale_id, sold_at::date, city, amount FROM rel.src_sales
WHERE sold_at >= :'day' AND sold_at < :'day'::date + 1;

TRUNCATE rel.daily_city;
INSERT INTO rel.daily_city
SELECT sale_date, city, count(*), sum(amount) FROM rel.fact_sales GROUP BY sale_date, city;
