-- Урок 3, шаг 5: три товара с наибольшей выручкой в каждой категории за 2025 год.
-- Столбцы: category, product_id, revenue, place (1, 2, 3). Отменённые продажи в выручку не входят.
-- При равной выручке выше товар с меньшим номером. Решите через LATERAL, как в разделе «Top-N в группе».
-- Выполнить: make psql F=practice/L03/top_products.sql      Проверить: make check-03
CREATE OR REPLACE VIEW reports.top_products AS
SELECT ...
