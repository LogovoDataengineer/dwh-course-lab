-- Урок 20: тот же запрос дашборда по вашей таблице предагрегатов shop.sales_daily.
SELECT day, category, sum(revenue) AS revenue, uniqHLL12Merge(buyers) AS buyers
FROM shop.sales_daily
WHERE day >= '2026-03-02' AND day < '2026-03-09'
GROUP BY day, category
ORDER BY day, category
SETTINGS log_comment = 'dashboard_mv'
FORMAT Null;
