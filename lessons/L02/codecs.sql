-- Урок 2: та же таблица, но столбцы со своими кодеками сжатия.
CREATE OR REPLACE TABLE dwh.sales_codecs
(
    sale_id     UInt64          CODEC(Delta, ZSTD(1)),  -- номера идут подряд: храним разницу соседних значений
    sold_at     DateTime        CODEC(Delta, ZSTD(1)),  -- время растёт: разница между соседними — несколько секунд
    customer_id UInt32          CODEC(ZSTD(3)),
    product_id  UInt32          CODEC(ZSTD(3)),
    category    LowCardinality(String),
    city        LowCardinality(String),
    quantity    UInt8,
    price       Decimal(10, 2)  CODEC(ZSTD(3)),
    status      LowCardinality(String)
)
ENGINE = MergeTree
ORDER BY (sold_at, sale_id);
INSERT INTO dwh.sales_codecs SELECT * FROM dwh.sales_history;
OPTIMIZE TABLE dwh.sales_codecs FINAL;
