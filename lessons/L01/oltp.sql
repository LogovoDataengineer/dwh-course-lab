-- Одна транзакция сайта: покупатель оформляет заказ.
\set cid random(1, 200000)
BEGIN;
SELECT city FROM web_customers WHERE customer_id = :cid;
INSERT INTO web_orders (customer_id, amount) VALUES (:cid, 990);
UPDATE web_customers SET last_order_at = now() WHERE customer_id = :cid;
COMMIT;
