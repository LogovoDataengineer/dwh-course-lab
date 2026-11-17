-- Урок 5, шаг 6: витрина «продажи по городам» в слое CDM базы dwh.
-- Столбцы: city — город покупателя из dds.customer (у заказов без покупателя — 'неизвестно'),
-- orders — число заказов, revenue — выручка без отменённых (0, если выручки нет).
-- Витрина строится из DDS, как cdm.daily_sales в lessons/L05/load.sql.
-- Выполнить: make psql DB=dwh F=practice/L05/city_sales.sql      Проверить: make check-05
DROP TABLE IF EXISTS cdm.city_sales;
CREATE TABLE cdm.city_sales AS
SELECT ...
