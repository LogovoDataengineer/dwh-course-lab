-- Урок 6: отчёт «выручка по городам и категориям» по нормализованной модели — пять таблиц.
\timing on
SELECT c.customer_city AS city, k.category, sum(i.quantity * i.price) AS revenue
FROM norm.order_items i
JOIN norm.orders o     ON o.order_id = i.order_id
JOIN norm.customers c  ON c.customer_id = o.customer_id
JOIN norm.products p   ON p.product_id = i.product_id
JOIN norm.categories k ON k.category_id = p.category_id
GROUP BY city, k.category
ORDER BY revenue DESC
LIMIT 5;
