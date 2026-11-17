-- Шаг 5. Витрина продаж по дням: идемпотентный пересчёт дней, которые затронула загрузка.
DELETE FROM cdm.daily_sales
WHERE sale_date IN (SELECT DISTINCT created_at::date FROM ods.orders WHERE batch_id = :batch);

INSERT INTO cdm.daily_sales
SELECT created_at::date, count(*), count(DISTINCT customer_id), sum(amount)
FROM ods.orders
WHERE status <> 'cancelled'
  AND created_at::date IN (SELECT DISTINCT created_at::date FROM ods.orders WHERE batch_id = :batch)
GROUP BY created_at::date;
