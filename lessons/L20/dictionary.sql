-- Урок 20: словарь товаров — ClickHouse держит каталог из PostgreSQL в памяти и обновляет его раз в 1–2 минуты.
CREATE OR REPLACE DICTIONARY shop.products_dict (product_id UInt64, name String, category String)
PRIMARY KEY product_id
SOURCE(POSTGRESQL(host 'postgres' port 5432 user 'dwh' password 'dwh' db 'shop' schema 'chx' table 'products'))
LAYOUT(FLAT())
LIFETIME(MIN 60 MAX 120);
SELECT dictGet('shop.products_dict', 'category', toUInt64(42)) AS category_of_42;
SELECT name, status, element_count, formatReadableSize(bytes_allocated) AS memory FROM system.dictionaries WHERE database = 'shop';
