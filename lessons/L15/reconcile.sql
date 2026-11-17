-- Урок 15: сверка ODS с источником — строки, которых нет в ODS или которые там устарели.
SELECT count(*) AS src_rows,
       count(*) FILTER (WHERE o.order_id IS NULL) AS missing_in_ods,
       count(*) FILTER (WHERE o.order_id IS NOT NULL AND (o.status, o.amount, o.updated_at) IS DISTINCT FROM (s.status, s.amount, s.updated_at)) AS stale_in_ods
FROM inc.src_orders s LEFT JOIN inc.orders o USING (order_id);
