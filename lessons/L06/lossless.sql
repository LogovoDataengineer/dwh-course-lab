-- Урок 6: ничего ли не потерялось? Собираем выгрузку обратно из нормализованных таблиц
-- и сравниваем с исходной построчно (EXCEPT ALL в обе стороны). Расхождения — только наши правила.
WITH rebuilt AS (
    SELECT o.order_id, o.order_date, o.customer_id, c.customer_name, c.customer_city,
           i.product_id, p.product_name, k.category, i.quantity, i.price
    FROM norm.order_items i
    JOIN norm.orders o     ON o.order_id = i.order_id
    JOIN norm.customers c  ON c.customer_id = o.customer_id
    JOIN norm.products p   ON p.product_id = i.product_id
    JOIN norm.categories k ON k.category_id = p.category_id
)
SELECT 'есть в выгрузке, нет в модели' AS side, count(*) AS lines FROM (SELECT * FROM norm.sales_flat EXCEPT ALL SELECT * FROM rebuilt) a
UNION ALL
SELECT 'есть в модели, нет в выгрузке', count(*) FROM (SELECT * FROM rebuilt EXCEPT ALL SELECT * FROM norm.sales_flat) b
UNION ALL
SELECT 'выручка совпадает', (SELECT sum(quantity * price) FROM norm.sales_flat) - (SELECT sum(quantity * price) FROM rebuilt);
