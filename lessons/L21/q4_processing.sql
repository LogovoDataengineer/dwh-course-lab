-- Служба поддержки: 100 самых старых заказов, застрявших в обработке.
SELECT order_id, customer_id, created_at FROM perf.orders WHERE status = 'processing' ORDER BY created_at LIMIT 100;
