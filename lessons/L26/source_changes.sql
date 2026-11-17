-- Урок 26: в магазине запустили мобильное приложение. Оно пишет заказы в ту же таблицу orders,
-- но статус — по-своему: с заглавной буквы и с пробелом в конце ('Delivered ', 'Paid ').
SET client_min_messages = warning;
DELETE FROM order_items WHERE order_id BETWEEN 41 AND 60;
DELETE FROM orders WHERE order_id BETWEEN 41 AND 60;
INSERT INTO orders (order_id, customer_id, created_at, status, updated_at)
SELECT 40 + n, 1 + n % 12, timestamp '2026-03-13 10:00' + n * interval '1 hour',
       CASE WHEN n % 3 = 0 THEN 'Paid ' ELSE 'Delivered ' END, timestamp '2026-03-13 10:00' + n * interval '1 hour'
FROM generate_series(1, 6) AS n;
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT 40 + n, 1 + n % 15, 1 + n % 2, 990 + n * 100 FROM generate_series(1, 6) AS n;
