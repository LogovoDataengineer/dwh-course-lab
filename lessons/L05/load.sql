-- Урок 5: один запуск загрузки хранилища: STG → ODS → DDS → CDM и запись в журнал.
SET client_min_messages = warning;
\set ON_ERROR_STOP on
SELECT coalesce(max(batch_id), 0) + 1 AS batch FROM meta.load_log \gset
INSERT INTO meta.load_log (batch_id, started_at, source_time) SELECT :batch, clock_timestamp(), now_at FROM src.legacy_clock;

-- STG: заказы, изменённые за последние сутки по часам источника, — все, как есть
INSERT INTO stg.orders_raw
SELECT o.order_id, o.customer_id, o.created_at, o.status, o.amount, o.updated_at, clock_timestamp(), 'legacy', :batch
FROM src.legacy_orders o, src.legacy_clock c
WHERE o.updated_at > c.now_at - interval '1 day';
-- справочник покупателей сайта — полной копией
INSERT INTO stg.site_customers_raw
SELECT customer_id::text, full_name, email, city, clock_timestamp(), :batch FROM src.customers;

-- ODS: последняя версия каждого заказа с правильными типами; что не приводится — в отбраковку
DROP TABLE IF EXISTS ods.orders, ods.orders_rejected;
CREATE TABLE ods.orders AS
WITH latest AS (
    SELECT *, row_number() OVER (PARTITION BY order_id ORDER BY src_updated_at DESC, load_dttm DESC) AS rn
    FROM stg.orders_raw
)
SELECT order_id::integer        AS order_id,
       customer_id::integer     AS customer_id,
       created_at::timestamp    AS created_at,
       lower(trim(status))      AS status,
       amount::numeric(12, 2)   AS amount,
       src_updated_at           AS updated_at
FROM latest
WHERE rn = 1 AND amount ~ '^[0-9]+(\.[0-9]+)?$';
CREATE TABLE ods.orders_rejected AS
SELECT DISTINCT ON (order_id) order_id, amount, 'сумма не число' AS reason, batch_id
FROM stg.orders_raw WHERE amount !~ '^[0-9]+(\.[0-9]+)?$'
ORDER BY order_id, load_dttm DESC;

-- DDS: единый покупатель из сайта и CRM, сведённых по email; заказы со ссылкой на покупателя
DROP TABLE IF EXISTS dds.customer CASCADE;
CREATE TABLE dds.customer AS
WITH site AS (
    SELECT DISTINCT ON (customer_id) customer_id::integer AS site_customer_id, full_name, lower(trim(email)) AS email, city
    FROM stg.site_customers_raw ORDER BY customer_id, load_dttm DESC
), crm AS (
    SELECT contact_id, lower(trim(email)) AS email, phone FROM stg.crm_contacts_raw
)
SELECT row_number() OVER (ORDER BY coalesce(site.email, crm.email)) AS customer_key,
       coalesce(site.email, crm.email) AS email, site.full_name, site.city, crm.phone,
       site.site_customer_id, crm.contact_id AS crm_contact_id
FROM site FULL JOIN crm ON crm.email = site.email;
DROP TABLE IF EXISTS dds.orders;
CREATE TABLE dds.orders AS
SELECT o.order_id, c.customer_key, o.created_at, o.status, o.amount
FROM ods.orders o LEFT JOIN dds.customer c ON c.site_customer_id = o.customer_id;

-- CDM: витрина «продажи по дням» для отчёта
DROP TABLE IF EXISTS cdm.daily_sales;
CREATE TABLE cdm.daily_sales AS
SELECT created_at::date AS sale_date,
       count(*) AS orders,
       sum(amount) FILTER (WHERE status <> 'cancelled') AS revenue,
       round(avg(amount) FILTER (WHERE status <> 'cancelled'), 0) AS avg_check
FROM dds.orders GROUP BY sale_date;

UPDATE meta.load_log SET
    stg_orders  = (SELECT count(*) FROM stg.orders_raw WHERE batch_id = :batch),
    ods_orders  = (SELECT count(*) FROM ods.orders),
    rejected    = (SELECT count(*) FROM ods.orders_rejected),
    finished_at = clock_timestamp()
WHERE batch_id = :batch;
SELECT batch_id, source_time, stg_orders, ods_orders, rejected, (finished_at - started_at)::interval(3) AS duration
FROM meta.load_log WHERE batch_id = :batch;
