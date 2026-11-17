-- Урок 20: пришли продажи 1 апреля — 200 тысяч строк обычной вставкой в shop.sales.
INSERT INTO shop.sales
SELECT 20000000 + number + 1, toDateTime('2026-04-01 00:00:00') + intDiv(number * 86400, 200000),
       1 + (number * 7919) % 5000, 1 + (number * 104729) % 300000, toDecimal64(100 + (number * 37) % 9000, 2)
FROM numbers(200000);
SELECT toDate(sold_at) AS day, count() AS sales, sum(amount) AS revenue FROM shop.sales WHERE day = '2026-04-01' GROUP BY day;
