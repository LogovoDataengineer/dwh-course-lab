-- Урок 27, шаг 3 (ваш): монитор качества ночных загрузок — представление dq.daily_checks.
-- Строка на каждый день и каждую проверку: check_date, check_name, value, failed (true — день не прошёл проверку).
-- Проверки (имена — ровно такие):
--   'duplicate_order_id'  — сколько лишних строк с повторным order_id; не прошёл, если больше 0 (готово ниже, образец);
--   'negative_amount'     — сколько заказов с отрицательной суммой; не прошёл, если больше 0;
--   'null_payment_method' — доля заказов без способа оплаты, %; единичные пустые значения бывают каждый день
--                           (около 0,1%) — это норма; не прошёл, если доля больше 5%;
--   'volume'              — число заказов за день; не прошёл, если оно меньше 60% МЕДИАНЫ предыдущих 7 дней.
--                           Не сравнивайте с соседним днём или средним: в выходные заказов на 30% больше, и
--                           наивное правило будет поднимать ложную тревогу каждые выходные. У первого дня истории
--                           нет — для него failed = false.
-- Выполнить: make psql DB=dwh F=practice/L27/checks.sql     Отчёт: make psql DB=dwh F=lessons/L27/report.sql
CREATE OR REPLACE VIEW dq.daily_checks AS
WITH days AS (
    SELECT order_date AS check_date,
           count(*) AS rows,
           count(*) - count(DISTINCT order_id) AS duplicates
    FROM dq.fact_orders
    GROUP BY order_date
)
SELECT check_date, 'duplicate_order_id' AS check_name, duplicates::numeric AS value, duplicates > 0 AS failed
FROM days
-- ЗАДАНИЕ: допишите остальные три проверки через UNION ALL
;
