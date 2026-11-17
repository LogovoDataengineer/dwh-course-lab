-- Урок 2: замер из теории — 10 млн продаж в ClickHouse (строки получаются формулами из номера).
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    sale_id     UInt64,
    sold_at     DateTime,
    customer_id UInt32,
    product_id  UInt32,
    category    String,
    city        String,
    quantity    UInt32,
    price       Decimal(10,2),
    status      String
) ENGINE = MergeTree ORDER BY sold_at;
INSERT INTO sales
SELECT number,
       toDateTime('2025-01-01 00:00:00', 'UTC') + (number % 31536000),
       1 + number % 200000,
       1 + number % 5000,
       ['Книги','Электроника','Дом','Спорт','Игрушки'][1 + number % 5],
       ['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'][1 + intDiv(number, 7) % 5],
       1 + number % 3,
       100 + (number % 900),
       ['delivered','delivered','delivered','paid','cancelled'][1 + intDiv(number, 3) % 5]
FROM numbers(1, 10000000);
