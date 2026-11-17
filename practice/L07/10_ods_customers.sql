-- Шаг 1. Покупатели в ODS: последняя версия каждого покупателя из всего, что пришло в STG,
-- с нормализацией значений. Повторный запуск ничего не портит: ON CONFLICT обновляет строку.
INSERT INTO ods.customers
SELECT customer_id::integer,
       trim(full_name),
       nullif(lower(trim(email)), ''),
       initcap(trim(city)),
       updated_at::timestamp
FROM (
    SELECT *, row_number() OVER (PARTITION BY customer_id ORDER BY updated_at::timestamp DESC, batch_id DESC) AS rn
    FROM stg.customers_raw
) v
WHERE rn = 1
ON CONFLICT (customer_id) DO UPDATE
SET full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, updated_at = EXCLUDED.updated_at;
