-- Урок 11: Data Vault 2.0 в хранилище. Схема stage_dv — источники через postgres_fdw, схема dv — хабы, линки, сателлиты.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS stage_dv CASCADE;
DROP SCHEMA IF EXISTS dv CASCADE;
CREATE SCHEMA stage_dv;
IMPORT FOREIGN SCHEMA public
    LIMIT TO (site_clock, site_customers, site_products, site_orders, site_order_items, loyalty_cards)
    FROM SERVER shop_src INTO stage_dv;
CREATE SCHEMA dv;

-- Хабы: только бизнес-ключ и технические поля
CREATE TABLE dv.hub_customer (hk_customer char(32) PRIMARY KEY, customer_id integer NOT NULL,
                              load_dts timestamp NOT NULL, record_source text NOT NULL);
CREATE TABLE dv.hub_product  (hk_product char(32) PRIMARY KEY, product_id integer NOT NULL,
                              load_dts timestamp NOT NULL, record_source text NOT NULL);
CREATE TABLE dv.hub_order    (hk_order char(32) PRIMARY KEY, order_id integer NOT NULL,
                              load_dts timestamp NOT NULL, record_source text NOT NULL);
-- Линки: связи хабов
CREATE TABLE dv.link_order_customer (hk_order_customer char(32) PRIMARY KEY, hk_order char(32) NOT NULL, hk_customer char(32) NOT NULL,
                                     load_dts timestamp NOT NULL, record_source text NOT NULL);
CREATE TABLE dv.link_order_product  (hk_order_product char(32) PRIMARY KEY, hk_order char(32) NOT NULL, hk_product char(32) NOT NULL,
                                     load_dts timestamp NOT NULL, record_source text NOT NULL);
-- Сателлиты: атрибуты с историей, только INSERT
CREATE TABLE dv.sat_customer (hk_customer char(32) NOT NULL, load_dts timestamp NOT NULL, hashdiff char(32) NOT NULL,
                              full_name text, city text, email text, record_source text NOT NULL,
                              PRIMARY KEY (hk_customer, load_dts));
CREATE TABLE dv.sat_product  (hk_product char(32) NOT NULL, load_dts timestamp NOT NULL, hashdiff char(32) NOT NULL,
                              name text, category text, price numeric(10, 2), record_source text NOT NULL,
                              PRIMARY KEY (hk_product, load_dts));
CREATE TABLE dv.sat_order    (hk_order char(32) NOT NULL, load_dts timestamp NOT NULL, hashdiff char(32) NOT NULL,
                              status text, amount numeric(12, 2), created_date date, record_source text NOT NULL,
                              PRIMARY KEY (hk_order, load_dts));
CREATE TABLE dv.sat_order_product (hk_order_product char(32) NOT NULL, load_dts timestamp NOT NULL, hashdiff char(32) NOT NULL,
                              quantity integer, price numeric(10, 2), record_source text NOT NULL,
                              PRIMARY KEY (hk_order_product, load_dts));
-- Журнал загрузок: одна строка на задание и дату
CREATE TABLE dv.load_log (load_dts timestamp NOT NULL, job text NOT NULL, rows bigint NOT NULL, seconds numeric(6, 1) NOT NULL,
                          PRIMARY KEY (load_dts, job));
