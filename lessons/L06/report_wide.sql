-- Урок 6: тот же отчёт по денормализованной витрине norm.sales_wide — одна таблица, без соединений.
\timing on
SELECT city, category, sum(line_total) AS revenue
FROM norm.sales_wide
GROUP BY city, category
ORDER BY revenue DESC
LIMIT 5;
