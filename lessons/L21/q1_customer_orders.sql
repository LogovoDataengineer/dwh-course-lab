-- Приложение, личный кабинет: последние 20 заказов покупателя.
\set cid random(1, 300000)
SELECT order_id, created_at, status, amount FROM perf.orders WHERE customer_id = :cid ORDER BY created_at DESC LIMIT 20;
