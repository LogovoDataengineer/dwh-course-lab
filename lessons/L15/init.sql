-- Урок 15: схема inc в хранилище — ODS заказов, отметка загрузки (watermark) и журналы.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS inc CASCADE;
CREATE SCHEMA inc;
IMPORT FOREIGN SCHEMA app LIMIT TO (orders) FROM SERVER shop_src INTO inc;
ALTER FOREIGN TABLE inc.orders RENAME TO src_orders;
CREATE TABLE inc.orders (order_id bigint PRIMARY KEY, customer_id integer, status text, amount numeric(10, 2), updated_at timestamptz);
CREATE TABLE inc.load_state (table_name text PRIMARY KEY, watermark timestamptz NOT NULL);
INSERT INTO inc.load_state VALUES ('orders', '1970-01-01');
-- одна строка на каждую загрузку: отметка до и после, сколько строк прочитано из источника
CREATE TABLE inc.load_log (load_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, run_id integer, loaded_at timestamptz DEFAULT clock_timestamp(),
                           watermark_before timestamptz, watermark_after timestamptz, rows_read integer);
-- одна строка на прогон run.sh: какой скрипт загрузки, сколько секунд работало приложение, сколько строк разошлось
CREATE TABLE inc.runs (run_id integer PRIMARY KEY, script text, seconds integer, loads integer, src_rows integer,
                       missed integer, finished_at timestamptz DEFAULT clock_timestamp());
