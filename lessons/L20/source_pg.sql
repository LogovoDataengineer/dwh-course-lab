-- Урок 20: каталог товаров живёт в базе сайта (PostgreSQL, схема chx) — ClickHouse читает его словарём.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS chx CASCADE;
CREATE SCHEMA chx;
CREATE TABLE chx.products AS
SELECT p AS product_id, 'Товар ' || p AS name,
       (ARRAY['Книги','Электроника','Дом','Одежда','Спорт','Игрушки','Красота','Продукты'])[1 + p % 8] AS category
FROM generate_series(1, 5000) AS p;
ALTER TABLE chx.products ADD PRIMARY KEY (product_id);
