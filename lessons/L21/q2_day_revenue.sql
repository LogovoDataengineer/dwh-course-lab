-- BI, отчёт за день: выручка и число заказов за выбранную дату (дату приводят к типу date прямо в условии).
\set d random(0, 179)
SELECT count(*), sum(amount) FROM perf.orders WHERE created_at::date = date '2025-10-01' + :d;
