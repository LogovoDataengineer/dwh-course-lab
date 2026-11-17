-- Урок 2, шаг 6: ваша компактная версия истории продаж. Цель — меньше 50 МиБ на диске.
-- Выполнить: make ch F=practice/L02/compact.sql      Проверить: make check-02
CREATE OR REPLACE TABLE dwh.sales_compact
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

INSERT INTO dwh.sales_compact SELECT * FROM dwh.sales_history;
OPTIMIZE TABLE dwh.sales_compact FINAL;
