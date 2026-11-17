-- Урок 14, сборка: STG — копия источников «Полки» в хранилище (схема polka_stg), чтобы модель
-- строилась из локальных таблиц, а не тянула данные из базы магазина на каждом соединении.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS polka_src CASCADE;
CREATE SCHEMA polka_src;
IMPORT FOREIGN SCHEMA polka FROM SERVER shop_src INTO polka_src;
DROP SCHEMA IF EXISTS polka_stg CASCADE;
CREATE SCHEMA polka_stg;
CREATE TABLE polka_stg.categories   AS SELECT * FROM polka_src.categories;
CREATE TABLE polka_stg.products     AS SELECT * FROM polka_src.products;
CREATE TABLE polka_stg.customers    AS SELECT * FROM polka_src.customers;
CREATE TABLE polka_stg.city_history AS SELECT * FROM polka_src.city_history;
CREATE TABLE polka_stg.orders       AS SELECT * FROM polka_src.orders;
CREATE TABLE polka_stg.order_items  AS SELECT * FROM polka_src.order_items;
CREATE TABLE polka_stg.payments     AS SELECT * FROM polka_src.payments;
CREATE INDEX ON polka_stg.city_history (customer_id, changed_at);
CREATE INDEX ON polka_stg.payments (order_id);
ANALYZE polka_stg.categories, polka_stg.products, polka_stg.customers, polka_stg.city_history,
        polka_stg.orders, polka_stg.order_items, polka_stg.payments;
DROP SCHEMA IF EXISTS polka CASCADE;
CREATE SCHEMA polka;
