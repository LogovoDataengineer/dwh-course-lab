-- Урок 11: информационная витрина поверх Data Vault — выручка доставленных заказов по текущему городу покупателя.
-- Аналитики читают витрину, а не хабы и сателлиты: здесь собраны все соединения и выбор последних версий.
SET client_min_messages = warning;
CREATE SCHEMA IF NOT EXISTS im;
CREATE OR REPLACE VIEW im.revenue_by_city AS
WITH order_now AS (
    SELECT DISTINCT ON (hk_order) hk_order, status, amount
    FROM dv.sat_order ORDER BY hk_order, load_dts DESC
), customer_now AS (
    SELECT DISTINCT ON (hk_customer) hk_customer, city
    FROM dv.sat_customer ORDER BY hk_customer, load_dts DESC
)
SELECT c.city, count(*) AS orders, sum(o.amount) AS revenue
FROM dv.link_order_customer l
JOIN order_now o    ON o.hk_order = l.hk_order
JOIN customer_now c ON c.hk_customer = l.hk_customer
WHERE o.status = 'delivered'
GROUP BY c.city;
\timing on
SELECT * FROM im.revenue_by_city ORDER BY revenue DESC;
