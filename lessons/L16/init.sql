-- Урок 16: схема rel в хранилище — факт продаж, витрина по дням и городам, журнал попыток загрузки.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS rel CASCADE;
CREATE SCHEMA rel;
IMPORT FOREIGN SCHEMA rel LIMIT TO (sales) FROM SERVER shop_src INTO rel;
ALTER FOREIGN TABLE rel.sales RENAME TO src_sales;
CREATE TABLE rel.fact_sales (sale_id bigint NOT NULL, sale_date date NOT NULL, city text NOT NULL, amount numeric(10, 2) NOT NULL);
CREATE INDEX ON rel.fact_sales (sale_date);
CREATE TABLE rel.daily_city (sale_date date NOT NULL, city text NOT NULL, sales integer NOT NULL, revenue numeric(14, 2) NOT NULL);
-- каждая попытка загрузки дня: чем закончилась (ok — дошла до конца, killed — оборвана)
CREATE TABLE rel.attempts (attempt_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, script text, day date, try integer,
                           outcome text, at timestamptz DEFAULT clock_timestamp());
