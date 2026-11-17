-- Урок 9: схема flow в хранилище dwh — ролевое измерение дат, мусорное измерение признаков,
-- накопительный снимок заказов. События и признаки читаются из базы сайта через postgres_fdw.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS flow CASCADE;
CREATE SCHEMA flow;
IMPORT FOREIGN SCHEMA public LIMIT TO (order_events, order_flags) FROM SERVER shop_src INTO flow;
ALTER FOREIGN TABLE flow.order_events RENAME TO src_order_events;
ALTER FOREIGN TABLE flow.order_flags RENAME TO src_order_flags;

-- Одно измерение дат — три роли в факте: создан, оплачен, доставлен
CREATE TABLE flow.dim_date AS
SELECT to_char(d, 'YYYYMMDD')::integer AS date_key, d::date AS full_date,
       extract(isodow FROM d) IN (6, 7) AS is_weekend, to_char(d, 'IYYY-"W"IW') AS iso_week
FROM generate_series(date '2025-10-25', date '2025-12-31', interval '1 day') AS d;
ALTER TABLE flow.dim_date ADD PRIMARY KEY (date_key);

-- Мусорное измерение: все встречающиеся сочетания признаков заказа в одной маленькой таблице
CREATE TABLE flow.dim_order_profile (
    profile_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel text NOT NULL, has_promo boolean NOT NULL, gift_wrap boolean NOT NULL,
    UNIQUE (channel, has_promo, gift_wrap)
);
INSERT INTO flow.dim_order_profile (channel, has_promo, gift_wrap)
SELECT DISTINCT channel, has_promo, gift_wrap FROM flow.src_order_flags ORDER BY 1, 2, 3;

-- Накопительный снимок: строка на заказ, этапы дописываются по мере наступления
CREATE TABLE flow.fact_order_pipeline (
    order_id          integer PRIMARY KEY,
    profile_key       integer REFERENCES flow.dim_order_profile,
    created_date_key  integer REFERENCES flow.dim_date,
    paid_date_key     integer REFERENCES flow.dim_date,
    delivered_date_key integer REFERENCES flow.dim_date,
    created_at timestamp, paid_at timestamp, shipped_at timestamp, delivered_at timestamp, cancelled_at timestamp,
    hours_to_deliver numeric(6, 1),              -- от оплаты до доставки
    updated_at timestamp NOT NULL
);
CREATE TABLE flow.load_log (load_day date PRIMARY KEY, events integer, new_orders integer, updated_orders integer, loaded_at timestamp DEFAULT clock_timestamp());
SELECT (SELECT count(*) FROM flow.dim_date) AS dates, (SELECT count(*) FROM flow.dim_order_profile) AS profiles;
