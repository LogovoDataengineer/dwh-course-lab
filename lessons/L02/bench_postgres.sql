DROP TABLE IF EXISTS sales;
-- 10 млн строк продаж в PostgreSQL: строковое хранение.
CREATE TABLE sales (
    sale_id     bigint,
    sold_at     timestamp,
    customer_id integer,
    product_id  integer,
    category    text,
    city        text,
    quantity    integer,
    price       numeric(10,2),
    status      text
);
INSERT INTO sales
SELECT g,
       timestamp '2025-01-01' + (g % 31536000) * interval '1 second',
       1 + g % 200000,
       1 + g % 5000,
       (ARRAY['Книги','Электроника','Дом','Спорт','Игрушки'])[1 + g % 5],
       (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + (g / 7) % 5],
       1 + g % 3,
       100 + (g % 900),
       (ARRAY['delivered','delivered','delivered','paid','cancelled'])[1 + (g / 3) % 5]
FROM generate_series(1, 10000000) AS g;
VACUUM ANALYZE sales;
