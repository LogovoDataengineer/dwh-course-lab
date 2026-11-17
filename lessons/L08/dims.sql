-- Урок 8: измерения звезды. Суррогатные ключи выдаёт хранилище, у каждого измерения — неизвестный член -1.
SET client_min_messages = warning;
DROP TABLE IF EXISTS mart.fact_sales, mart.dim_date, mart.dim_product, mart.dim_customer;

-- Даты 2025 года; ключ — число вида 20250315, праздники — из производственного календаря
CREATE TABLE mart.dim_date (
    date_key    integer PRIMARY KEY,
    full_date   date NOT NULL,
    year        integer NOT NULL,
    quarter     integer NOT NULL,
    month       integer NOT NULL,
    month_name  text NOT NULL,
    day_of_week integer NOT NULL,          -- 1 понедельник … 7 воскресенье
    is_weekend  boolean NOT NULL,
    is_holiday  boolean NOT NULL
);
INSERT INTO mart.dim_date
SELECT to_char(d, 'YYYYMMDD')::integer, d, extract(year FROM d), extract(quarter FROM d), extract(month FROM d),
       (ARRAY['январь','февраль','март','апрель','май','июнь','июль','август','сентябрь','октябрь','ноябрь','декабрь'])[extract(month FROM d)],
       extract(isodow FROM d), extract(isodow FROM d) IN (6, 7),
       d IN ('2025-01-01','2025-01-02','2025-01-03','2025-01-06','2025-01-07','2025-01-08','2025-05-01','2025-05-02',
             '2025-05-08','2025-05-09','2025-06-12','2025-06-13','2025-11-03','2025-11-04','2025-12-31')
FROM generate_series(date '2025-01-01', date '2025-12-31', interval '1 day') AS d;

CREATE TABLE mart.dim_product (
    product_key   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id    integer NOT NULL UNIQUE,     -- бизнес-ключ из источника
    product_name  text NOT NULL,
    category      text NOT NULL,
    brand         text NOT NULL
);
INSERT INTO mart.dim_product (product_key, product_id, product_name, category, brand) OVERRIDING SYSTEM VALUE
VALUES (-1, -1, 'Неизвестный товар', 'Неизвестно', 'Неизвестно');
INSERT INTO mart.dim_product (product_id, product_name, category, brand)
SELECT product_id, product_name, category, brand FROM src.product_catalog ORDER BY product_id;

-- Покупатель с городом последней покупки (история городов — урок 10)
CREATE TABLE mart.dim_customer (
    customer_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  integer NOT NULL UNIQUE,
    city         text NOT NULL
);
INSERT INTO mart.dim_customer (customer_key, customer_id, city) OVERRIDING SYSTEM VALUE VALUES (-1, -1, 'Неизвестно');
INSERT INTO mart.dim_customer (customer_id, city)
SELECT DISTINCT ON (customer_id) customer_id, city FROM src.sales_history ORDER BY customer_id, sold_at DESC;

ANALYZE mart.dim_date, mart.dim_product, mart.dim_customer;
SELECT (SELECT count(*) FROM mart.dim_date) AS dates, (SELECT count(*) FROM mart.dim_product) AS products,
       (SELECT count(*) FROM mart.dim_customer) AS customers;
