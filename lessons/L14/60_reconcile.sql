-- Урок 14, сборка: сверка модели с источником — строки и сумма, неизвестные члены, воронка.
SELECT 'источник' AS side, count(*) AS lines, sum(i.quantity * i.price) AS amount
FROM polka_stg.order_items i
UNION ALL
SELECT 'fact_sales', count(*), sum(amount) FROM polka.fact_sales
ORDER BY side DESC;
SELECT count(*) FILTER (WHERE customer_key = 0) AS unknown_customer_lines,
       count(*) FILTER (WHERE product_key = 0)  AS unknown_product_lines
FROM polka.fact_sales;
