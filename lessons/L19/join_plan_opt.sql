-- Урок 19: тот же запрос по вашей таблице mpp.payments_opt.
\timing on
EXPLAIN ANALYZE
SELECT p.method, count(*) AS payments, sum(p.amount) AS revenue
FROM mpp.orders o JOIN mpp.payments_opt p ON p.order_id = o.order_id
WHERE o.status = 'delivered' AND p.paid_at >= '2026-02-01' AND p.paid_at < '2026-03-01'
GROUP BY p.method;
