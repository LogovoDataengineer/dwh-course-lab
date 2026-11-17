-- Шаг 2. Заказы: последняя версия каждого заказа, причина отбраковки вычисляется один раз.
-- Отбраковка пересчитывается заново каждой загрузкой: если покупатель-«сирота» пришёл позже,
-- его заказы сами переезжают из отбраковки в ODS.
DROP TABLE IF EXISTS stg.orders_checked;
CREATE TABLE stg.orders_checked AS
SELECT v.*,
       CASE WHEN v.amount !~ '^[0-9]+(\.[0-9]+)?$' THEN 'bad amount'
            WHEN NOT EXISTS (SELECT 1 FROM ods.customers c WHERE c.customer_id = v.customer_id::integer) THEN 'unknown customer'
            -- ЗАДАНИЕ (шаг 6): добавьте правило 'unknown status' для статусов вне списка
            -- created, paid, delivered, cancelled (после lower и trim)
       END AS reason
FROM (
    SELECT *, row_number() OVER (PARTITION BY order_id ORDER BY batch_id DESC) AS rn
    FROM stg.orders_raw
) v
WHERE rn = 1;

INSERT INTO ods.orders
SELECT order_id::integer, customer_id::integer, created_at::timestamp, lower(trim(status)), amount::numeric, batch_id
FROM stg.orders_checked WHERE reason IS NULL
ON CONFLICT (order_id) DO UPDATE
SET customer_id = EXCLUDED.customer_id, created_at = EXCLUDED.created_at, status = EXCLUDED.status,
    amount = EXCLUDED.amount, batch_id = EXCLUDED.batch_id;
-- заказ, который раньше был хорошим, а в новой версии стал битым, из ODS убираем
DELETE FROM ods.orders o USING stg.orders_checked c WHERE c.order_id::integer = o.order_id AND c.reason IS NOT NULL;

TRUNCATE ods.orders_rejected;
INSERT INTO ods.orders_rejected SELECT order_id, batch_id, reason FROM stg.orders_checked WHERE reason IS NOT NULL;
