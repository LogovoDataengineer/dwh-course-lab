-- Урок 20: статусы заказов в ReplacingMergeTree — строк больше, чем заказов, пока куски не слились.
SELECT count() AS rows, uniqExact(order_id) AS orders FROM shop.order_status;
SELECT status, count() AS orders FROM shop.order_status FINAL GROUP BY status ORDER BY status;
SELECT status, count() AS orders
FROM (SELECT order_id, argMax(status, version) AS status FROM shop.order_status GROUP BY order_id)
GROUP BY status ORDER BY status;
