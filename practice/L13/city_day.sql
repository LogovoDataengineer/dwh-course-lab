-- Урок 13, шаг 7: витрина «город — день — класс» для дашборда операционного директора, в ClickHouse.
-- Создайте таблицу taxi.city_day со столбцами (порядок важен):
--   trip_date, city, car_class, trips, revenue, distance_km, bonus_amount
-- Только завершённые поездки (status = 'completed'). trips — число поездок, остальные меры — суммы.
-- Храните только АДДИТИВНЫЕ меры: никаких средних и отношений. Цену километра и долю бонусов
-- дашборд посчитает сам как отношение сумм — и за день, и за неделю, и за квартал.
-- Выполнить: make ch F=practice/L13/city_day.sql      Проверить: make check-13
CREATE OR REPLACE TABLE taxi.city_day ENGINE = MergeTree ORDER BY (trip_date, city, car_class) AS
SELECT ...
