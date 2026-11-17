-- Урок 10: CRM «Полки» в базе сайта — текущее состояние покупателей (история источником не хранится).
-- Каждый день tick.sql меняет CRM: переезды, смена сегмента, исправленные email, новые покупатели и заказы.
SET client_min_messages = warning;
DROP TABLE IF EXISTS crm_customers, crm_orders, crm_clock;
CREATE TABLE crm_clock (today date NOT NULL);
INSERT INTO crm_clock VALUES ('2025-10-31');
SELECT setseed(0.1010) \g /dev/null
CREATE TABLE crm_customers AS
SELECT c AS customer_id,
       'Покупатель ' || c AS full_name,
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 6)::int] AS city,
       (ARRAY['new','silver','silver','gold'])[1 + floor(random() * 4)::int] AS segment,
       'user' || c || '@mail.example' AS email
FROM generate_series(1, 20000) AS c;
ALTER TABLE crm_customers ADD PRIMARY KEY (customer_id);
CREATE TABLE crm_orders (order_id bigserial PRIMARY KEY, customer_id integer NOT NULL, order_date date NOT NULL, amount numeric(10, 2) NOT NULL);
