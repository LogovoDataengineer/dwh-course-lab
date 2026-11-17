-- Урок 16, шаг 4 (ваш): загрузка дня, которую можно обрывать и повторять сколько угодно.
-- Сейчас это копия lessons/L16/load_naive.sql. Переделайте её так, чтобы:
--   1) повтор дня не задваивал продажи — загрузка ИДЕМПОТЕНТНА: сначала убрать день из факта, затем вставить;
--   2) обрыв на любой строке не оставлял полдня или факт без витрины — загрузка АТОМАРНА: всё в одной транзакции
--      (BEGIN ... COMMIT; оборванная транзакция откатывается целиком);
--   3) витрина пересчитывалась только за загружаемый день, а не вся целиком.
-- Переменная day — день загрузки. Запуск под обрывами: bash lessons/L16/chaos.sh practice/L16/load_day.sql 2026-02-01 2026-02-28
INSERT INTO rel.fact_sales
SELECT sale_id, sold_at::date, city, amount FROM rel.src_sales
WHERE sold_at >= :'day' AND sold_at < :'day'::date + 1;

TRUNCATE rel.daily_city;
INSERT INTO rel.daily_city
SELECT sale_date, city, count(*), sum(amount) FROM rel.fact_sales GROUP BY sale_date, city;
