-- Урок 19: план агрегации по перекошенной таблице: сколько строк обработал самый загруженный сегмент.
EXPLAIN ANALYZE
SELECT customer_id, sum(amount) AS revenue FROM mpp.sales_by_customer GROUP BY customer_id;
