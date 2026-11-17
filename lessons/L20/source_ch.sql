-- Урок 20: продажи в ClickHouse — 20 миллионов строк за 90 дней. Таблицу сделали «как получилось»:
-- ключ сортировки — номер продажи, о запросах дашборда при проектировании не думали.
DROP DATABASE IF EXISTS shop SYNC;
CREATE DATABASE shop;
CREATE TABLE shop.sales (
    sale_id     UInt64,
    sold_at     DateTime,
    product_id  UInt32,
    customer_id UInt32,
    amount      Decimal(10, 2)
) ENGINE = MergeTree ORDER BY sale_id;
INSERT INTO shop.sales
SELECT number + 1,
       toDateTime('2026-01-01 00:00:00') + intDiv(number * 90 * 86400, 20000000),
       1 + (number * 7919) % 5000,
       1 + (number * 104729) % 300000,
       toDecimal64(100 + (number * 37) % 9000, 2)
FROM numbers(20000000);
OPTIMIZE TABLE shop.sales FINAL;
-- статусы заказов приходят из CDC новыми версиями строки: заказ, статус, версия (позиция в журнале источника)
CREATE TABLE shop.order_status (order_id UInt64, status LowCardinality(String), version UInt64)
ENGINE = ReplacingMergeTree(version) ORDER BY order_id;
SYSTEM STOP MERGES shop.order_status;
INSERT INTO shop.order_status SELECT number + 1, 'created', 1 FROM numbers(1000000);
INSERT INTO shop.order_status SELECT number + 1, 'paid', 2 FROM numbers(1000000) WHERE number % 10 < 9;
INSERT INTO shop.order_status SELECT number + 1, if(number % 13 = 0, 'cancelled', 'delivered'), 3 FROM numbers(1000000) WHERE number % 10 < 7;
