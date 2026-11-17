-- Урок 14, модель «Полки». Шаг 4 (ваш): факт продаж polka.fact_sales.
-- Зерно — строка заказа (polka_stg.order_items). Столбцы, порядок важен:
--   date_key, customer_key, product_key, order_id, status, quantity, amount
-- date_key — день создания заказа (ГГГГММДД); amount = quantity * price строки.
-- customer_key — версия покупателя, ДЕЙСТВОВАВШАЯ В МОМЕНТ ЗАКАЗА (created_at в [valid_from, valid_to)).
-- Не нашлась версия или товар — ключ 0 (неизвестный член). Ни одна строка заказа не должна потеряться:
-- сверка после сборки сравнит число строк и сумму с источником.
-- Образец — шаг 4 теории урока. Собрать модель: bash lessons/L14/build.sh
CREATE TABLE polka.fact_sales AS
SELECT ...
