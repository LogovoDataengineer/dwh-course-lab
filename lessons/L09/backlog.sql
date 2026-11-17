-- Урок 9: периодический снимок из накопительного — сколько оплаченных заказов «в пути» на конец каждого дня.
SET client_min_messages = warning;
-- День календаря соединяется с каждым заказом: заказ в пути, если оплачен до конца дня,
-- а доставлен или отменён позже (или ещё нет). Дни без событий тоже получают строку.
DROP TABLE IF EXISTS flow.fact_backlog_daily;
CREATE TABLE flow.fact_backlog_daily AS
SELECT d.date_key, d.full_date,
       count(f.order_id) AS in_transit,
       count(f.order_id) FILTER (WHERE f.paid_at < d.full_date - 3) AS older_than_3_days
FROM flow.dim_date d
LEFT JOIN flow.fact_order_pipeline f
       ON f.paid_at < d.full_date + 1
      AND coalesce(f.delivered_at, f.cancelled_at, 'infinity') >= d.full_date + 1
WHERE d.full_date BETWEEN '2025-11-01' AND '2025-12-12'
GROUP BY d.date_key, d.full_date;
SELECT full_date, in_transit, older_than_3_days FROM flow.fact_backlog_daily
WHERE full_date IN ('2025-11-01', '2025-11-05', '2025-11-15', '2025-11-30', '2025-12-05', '2025-12-12') ORDER BY full_date;
