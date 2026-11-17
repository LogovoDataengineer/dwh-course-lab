-- Урок 1. База сайта «Полки» с историей продаж за 2025 год и рабочими таблицами для нагрузки.
-- Запускается командой make lesson-01; повторный запуск ничего не ломает.
SET client_min_messages = warning;
CREATE TABLE IF NOT EXISTS sales_history (
    sale_id     bigint PRIMARY KEY,
    sold_at     timestamp NOT NULL,
    customer_id integer NOT NULL,
    product_id  integer NOT NULL,
    category    text NOT NULL,
    city        text NOT NULL,
    quantity    integer NOT NULL,
    price       numeric(10,2) NOT NULL,
    status      text NOT NULL
);
-- setseed делает «случайные» данные одинаковыми у всех: цифры в уроке совпадут с вашими.
-- Как в жизни: продажи растут к концу года, электроника дороже книг,
-- а чем дальше город от склада в Москве, тем чаще покупатели отменяют заказ.
SELECT setseed(0.42) \g /dev/null
INSERT INTO sales_history
SELECT g,
       timestamp '2025-01-01' + floor(power(g / 5000000.0, 0.8) * 31535999) * interval '1 second',
       1 + floor(r_customer * 200000)::int,
       1 + c * 1000 + floor(r_product * 1000)::int,
       (ARRAY['Книги','Электроника','Дом','Спорт','Игрушки'])[1 + c],
       (ARRAY['Москва','Москва','Москва','Санкт-Петербург','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + t],
       1 + floor(r_qty * 3)::int,
       round(((ARRAY[300, 1500, 500, 500, 400])[1 + c] + r_price * (ARRAY[1200, 13500, 4500, 5500, 3600])[1 + c])::numeric, -1),
       CASE WHEN r_cancel < (ARRAY[0.08, 0.08, 0.08, 0.10, 0.10, 0.12, 0.14, 0.18])[1 + t] THEN 'cancelled'
            WHEN r_status < 0.8 THEN 'delivered' ELSE 'paid' END
FROM (SELECT g, floor(random() * 5)::int AS c, floor(random() * 8)::int AS t,
             random() AS r_customer, random() AS r_product, random() AS r_qty, random() AS r_price,
             random() AS r_cancel, random() AS r_status
      FROM generate_series(1::bigint, 5000000) AS g) AS r
WHERE NOT EXISTS (SELECT 1 FROM sales_history);
CREATE INDEX IF NOT EXISTS sales_history_customer_idx ON sales_history (customer_id);

-- Таблицы, в которые «пишет сайт» во время замера нагрузки
CREATE TABLE IF NOT EXISTS web_customers (customer_id integer PRIMARY KEY, city text, last_order_at timestamp);
INSERT INTO web_customers
SELECT g, (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + g % 5], NULL
FROM generate_series(1, 200000) g
ON CONFLICT DO NOTHING;
CREATE TABLE IF NOT EXISTS web_orders (order_id bigserial PRIMARY KEY, customer_id integer NOT NULL, amount numeric(10,2), created_at timestamp DEFAULT now());
VACUUM ANALYZE sales_history;
VACUUM ANALYZE web_customers;
SELECT count(*) AS sales_history_rows FROM sales_history;
