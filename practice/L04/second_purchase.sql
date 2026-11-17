-- Урок 4, шаг 5: сколько дней проходит от первой покупки до второй.
-- Для каждого покупателя возьмите две первые неотменённые покупки (по sold_at, при равенстве — по sale_id).
-- Столбцы: city — город первой покупки, customers — сколько покупателей сделали вторую покупку,
-- avg_days — средний разрыв в днях с дробной частью, round(..., 1). Пригодятся row_number и lead.
-- Выполнить: make psql F=practice/L04/second_purchase.sql      Проверить: make check-04
CREATE OR REPLACE VIEW reports.second_purchase AS
SELECT ...
