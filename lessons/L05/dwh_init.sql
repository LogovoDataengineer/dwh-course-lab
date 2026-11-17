-- Урок 5: хранилище — отдельная база dwh. Слои — схемы stg, ods, dds, cdm; журнал загрузок — meta.
-- Источник подключён через postgres_fdw: таблицы базы сайта видны в схеме src как «внешние».
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DROP SERVER IF EXISTS shop_src CASCADE;
CREATE SERVER shop_src FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'shop');
CREATE USER MAPPING FOR dwh SERVER shop_src OPTIONS (user 'dwh', password 'dwh');
DROP SCHEMA IF EXISTS src, stg, ods, dds, cdm, meta CASCADE;
CREATE SCHEMA src; CREATE SCHEMA stg; CREATE SCHEMA ods; CREATE SCHEMA dds; CREATE SCHEMA cdm; CREATE SCHEMA meta;
IMPORT FOREIGN SCHEMA public LIMIT TO (legacy_orders, legacy_clock, customers) FROM SERVER shop_src INTO src;

-- Журнал загрузок: одна строка на запуск
CREATE TABLE meta.load_log (
    batch_id    integer PRIMARY KEY,
    started_at  timestamp NOT NULL,
    source_time timestamp,
    stg_orders  integer,
    ods_orders  integer,
    rejected    integer,
    finished_at timestamp
);

-- STG: всё строками, как пришло, плюс когда и каким запуском загружено
CREATE TABLE stg.orders_raw (order_id text, customer_id text, created_at text, status text, amount text,
                             src_updated_at timestamp, load_dttm timestamp NOT NULL, src_system text NOT NULL, batch_id integer NOT NULL);
CREATE TABLE stg.site_customers_raw (customer_id text, full_name text, email text, city text,
                                     load_dttm timestamp NOT NULL, batch_id integer NOT NULL);
CREATE TABLE stg.crm_contacts_raw (contact_id text, name text, email text, phone text,
                                   load_dttm timestamp NOT NULL DEFAULT now(), batch_id integer NOT NULL DEFAULT 0);
