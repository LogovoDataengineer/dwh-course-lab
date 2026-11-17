-- Урок 20: запрос дашборда — выручка и покупатели по категориям за неделю, по дням.
SELECT
       toDate(sold_at) AS day, dictGet('shop.products_dict', 'category', toUInt64(product_id)) AS category,
       sum(amount) AS revenue, uniqHLL12(customer_id) AS buyers
FROM shop.sales
WHERE sold_at >= '2026-03-02' AND sold_at < '2026-03-09'
GROUP BY day, category
ORDER BY day, category
SETTINGS log_comment = 'dashboard', use_query_condition_cache = 0
FORMAT Null;
