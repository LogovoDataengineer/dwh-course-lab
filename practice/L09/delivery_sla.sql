-- Урок 9, шаг 6: держим ли мы обещание «доставка за 5 дней»? Представление flow.delivery_sla в базе dwh.
-- Строка на канал заказа (channel из мусорного измерения flow.dim_order_profile). Столбцы:
--   channel; delivered — сколько заказов доставлено; avg_hours — среднее hours_to_deliver, round(..., 1);
--   on_time_pct — доля доставленных не дольше 120 часов от оплаты, в процентах, round(..., 1).
-- Считаются только доставленные заказы. Источник — накопительный снимок flow.fact_order_pipeline.
-- Выполнить: make psql DB=dwh F=practice/L09/delivery_sla.sql      Проверить: make check-09
CREATE OR REPLACE VIEW flow.delivery_sla AS
SELECT ...
