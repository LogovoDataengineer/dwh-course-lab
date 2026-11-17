-- Урок 25: в хранилище — заказы сайта через postgres_fdw (af.src_orders) и витрина выручки по дням и городам.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS af CASCADE;
CREATE SCHEMA af;
IMPORT FOREIGN SCHEMA af LIMIT TO (orders) FROM SERVER shop_src INTO af;
ALTER FOREIGN TABLE af.orders RENAME TO src_orders;
CREATE TABLE af.daily_revenue (day date NOT NULL, city text NOT NULL, orders integer NOT NULL, revenue numeric(14, 2) NOT NULL,
                               loaded_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE af.naive_revenue (LIKE af.daily_revenue INCLUDING ALL);
