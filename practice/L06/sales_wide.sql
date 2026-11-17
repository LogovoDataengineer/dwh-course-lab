-- Урок 6, шаг 6: денормализованная витрина norm.sales_wide — нормализованная модель, соединённая заранее.
-- Одна строка — одна строка заказа (как norm.order_items). Обязательные столбцы:
--   order_id, line_no, order_date, customer_id, city, product_name, category, quantity, price, line_total (= quantity * price)
-- Выполнить: make psql F=practice/L06/sales_wide.sql      Сравнить скорость: make psql F=lessons/L06/report_wide.sql
-- Проверить: make check-06
DROP TABLE IF EXISTS norm.sales_wide;
CREATE TABLE norm.sales_wide AS
SELECT ...
