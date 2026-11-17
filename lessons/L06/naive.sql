-- Урок 6: «просто разложим по таблицам» — с ключами, но без правил для противоречий в выгрузке.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS naive CASCADE;
CREATE SCHEMA naive;
CREATE TABLE naive.customers (customer_id integer PRIMARY KEY, customer_name text NOT NULL, customer_city text NOT NULL);
INSERT INTO naive.customers
SELECT DISTINCT customer_id, customer_name, customer_city FROM norm.sales_flat;
