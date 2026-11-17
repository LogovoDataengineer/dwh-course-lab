-- Урок 7: практикум пересоздаёт хранилище в базе dwh — слои stg, ods, cdm и журнал meta.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS src, stg, ods, dds, cdm, meta CASCADE;
CREATE SCHEMA stg; CREATE SCHEMA ods; CREATE SCHEMA cdm; CREATE SCHEMA meta;
CREATE TABLE stg.customers_raw (customer_id text, full_name text, email text, city text, updated_at text,
                                batch_id integer NOT NULL DEFAULT 0, load_dttm timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE stg.orders_raw    (order_id text, customer_id text, created_at text, status text, amount text,
                                batch_id integer NOT NULL DEFAULT 0, load_dttm timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE ods.customers (customer_id integer PRIMARY KEY, full_name text NOT NULL, email text, city text NOT NULL, updated_at timestamp NOT NULL);
CREATE TABLE ods.orders (order_id integer PRIMARY KEY, customer_id integer NOT NULL REFERENCES ods.customers,
                         created_at timestamp NOT NULL, status text NOT NULL, amount numeric(10, 2) NOT NULL, batch_id integer NOT NULL);
CREATE TABLE ods.orders_rejected (order_id text PRIMARY KEY, batch_id integer NOT NULL, reason text NOT NULL);
CREATE TABLE meta.load_log (batch_id integer NOT NULL, target text NOT NULL, rows_loaded integer, rows_rejected integer,
                            lost integer, loaded_at timestamp NOT NULL DEFAULT clock_timestamp());
CREATE TABLE cdm.daily_sales (sale_date date PRIMARY KEY, orders integer NOT NULL, buyers integer NOT NULL, revenue numeric(12, 2) NOT NULL);
