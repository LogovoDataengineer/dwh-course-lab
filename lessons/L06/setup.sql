-- Урок 6: выгрузка менеджера «продажи за январь — апрель» одной плоской таблицей, как из Excel.
-- Строка — товар в заказе, и в ней же всё о покупателе и товаре. В выгрузке есть аномалии:
-- покупатели, у которых в разных строках разный город, и товары, переименованные посреди выгрузки.
SET client_min_messages = warning;
CREATE SCHEMA IF NOT EXISTS norm;
DROP TABLE IF EXISTS norm.sales_flat;
CREATE TABLE norm.sales_flat AS
WITH lines AS (
    SELECT sale_id, sold_at, product_id, category, quantity, price,
           (sale_id + 2) / 3 AS order_id,                                   -- по три строки в заказе
           first_value(customer_id) OVER (PARTITION BY (sale_id + 2) / 3 ORDER BY sale_id) AS customer_id
    FROM sales_history
    WHERE sale_id <= 600000 AND status <> 'cancelled'
)
SELECT order_id,
       sold_at::date                                                           AS order_date,
       customer_id,
       'Покупатель ' || customer_id                                            AS customer_name,
       CASE WHEN customer_id % 997 = 0 AND order_id % 2 = 0 THEN 'Казань'      -- переехал или ошибка ввода?
            ELSE (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + customer_id % 5] END AS customer_city,
       product_id,
       CASE WHEN product_id % 250 = 0 AND sold_at >= '2025-03-01' THEN 'Товар ' || product_id || ' (новая упаковка)'
            ELSE 'Товар ' || product_id END                                    AS product_name,
       category,
       quantity,
       price
FROM lines;
SELECT count(*) AS lines, count(DISTINCT order_id) AS orders, count(DISTINCT customer_id) AS customers,
       count(DISTINCT product_id) AS products FROM norm.sales_flat;
