-- Урок 3: отчёт директору «Полки» за 2025 год — три представления в схеме reports.
CREATE SCHEMA IF NOT EXISTS reports;

-- 1. Сводная по городам и месяцам: продажи, выручка и доля отмен (условная агрегация FILTER)
CREATE OR REPLACE VIEW reports.city_month AS
SELECT city,
       date_trunc('month', sold_at)::date                              AS month,
       count(*) FILTER (WHERE status <> 'cancelled')                   AS sales,
       sum(quantity * price) FILTER (WHERE status <> 'cancelled')      AS revenue,
       round(100.0 * count(*) FILTER (WHERE status = 'cancelled') / count(*), 1) AS cancel_pct
FROM sales_history
GROUP BY city, month;

-- 2. Выручка по кварталам и категориям с подытогами и общим итогом (ROLLUP и GROUPING)
CREATE OR REPLACE VIEW reports.category_rollup AS
SELECT CASE WHEN GROUPING(quarter) = 1 THEN 'Весь год' ELSE quarter END       AS quarter,
       CASE WHEN GROUPING(category) = 1 THEN 'Все категории' ELSE category END AS category,
       sum(quantity * price)                                                     AS revenue
FROM (SELECT 'Q' || extract(quarter FROM sold_at) AS quarter, category, quantity, price
      FROM sales_history WHERE status <> 'cancelled') s
GROUP BY ROLLUP (quarter, category);

-- 3. Медиана и 90-й перцентиль чека по городам: среднее искажают крупные покупки
CREATE OR REPLACE VIEW reports.city_check AS
SELECT city,
       round(avg(quantity * price), 0)                                              AS avg_check,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY quantity * price)               AS median_check,
       percentile_cont(0.9) WITHIN GROUP (ORDER BY quantity * price)               AS p90_check
FROM sales_history
WHERE status <> 'cancelled'
GROUP BY city;
