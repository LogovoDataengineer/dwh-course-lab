-- Урок 1: копия истории продаж в ClickHouse — наше первое «хранилище».
CREATE DATABASE IF NOT EXISTS dwh;
CREATE OR REPLACE TABLE dwh.sales_history
(
    sale_id     UInt64,
    sold_at     DateTime,
    customer_id UInt32,
    product_id  UInt32,
    category    LowCardinality(String),
    city        LowCardinality(String),
    quantity    UInt8,
    price       Decimal(10, 2),
    status      LowCardinality(String)
)
ENGINE = MergeTree
ORDER BY (sold_at, sale_id);
-- Табличная функция postgresql() читает таблицу прямо из базы сайта
INSERT INTO dwh.sales_history
SELECT * FROM postgresql('postgres:5432', 'shop', 'sales_history', 'dwh', 'dwh');
SELECT count() AS rows FROM dwh.sales_history;
