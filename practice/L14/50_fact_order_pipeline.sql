-- Урок 14, модель «Полки». Шаг 5 (ваш): воронка заказов polka.fact_order_pipeline — строка на заказ.
-- Столбцы, порядок важен: order_id, customer_key, created_at, paid_at, delivered_at, cancelled_at, hours_to_pay
--   paid_at      — момент УСПЕШНОЙ оплаты (в polka_stg.payments есть и неуспешные попытки, status = 'failed');
--   delivered_at — updated_at заказа со статусом delivered, cancelled_at — со статусом cancelled, иначе NULL;
--   hours_to_pay — часы от создания заказа до успешной оплаты, округлённые до 0.1;
--   customer_key — как в факте продаж: версия на момент заказа, иначе 0.
-- Собрать модель: bash lessons/L14/build.sh
CREATE TABLE polka.fact_order_pipeline AS
SELECT ...
