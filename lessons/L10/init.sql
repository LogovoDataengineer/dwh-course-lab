-- Урок 10: схема scd в хранилище — измерение покупателей SCD2 и факт заказов со ссылкой на версию.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS scd CASCADE;
CREATE SCHEMA scd;
IMPORT FOREIGN SCHEMA public LIMIT TO (crm_customers, crm_orders, crm_clock) FROM SERVER shop_src INTO scd;
CREATE TABLE scd.dim_customer (
    customer_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  integer NOT NULL,
    full_name    text NOT NULL,
    city         text NOT NULL,
    segment      text NOT NULL,
    email        text,
    valid_from   date NOT NULL,
    valid_to     date NOT NULL DEFAULT '9999-12-31',
    is_current   boolean NOT NULL DEFAULT true,
    hashdiff     text NOT NULL
);
CREATE UNIQUE INDEX dim_customer_current ON scd.dim_customer (customer_id) WHERE is_current;
CREATE TABLE scd.fact_orders (order_id bigint PRIMARY KEY, customer_key integer NOT NULL REFERENCES scd.dim_customer,
                              order_date date NOT NULL, amount numeric(10, 2) NOT NULL);
CREATE TABLE scd.load_log (load_date date PRIMARY KEY, closed integer, inserted integer, orders integer, loaded_at timestamp DEFAULT clock_timestamp());
