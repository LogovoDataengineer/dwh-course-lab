-- Урок 2: та же таблица, но строки отсортированы по городу, категории и статусу.
CREATE OR REPLACE TABLE dwh.sales_by_city
AS dwh.sales_history
ENGINE = MergeTree
ORDER BY (city, category, status, sold_at);
INSERT INTO dwh.sales_by_city SELECT * FROM dwh.sales_history;
OPTIMIZE TABLE dwh.sales_by_city FINAL;
