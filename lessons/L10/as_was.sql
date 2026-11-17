-- Урок 10: выручка ноября по сегментам — «как было» (сегмент в день заказа) и «как сейчас» (текущий сегмент).
SELECT d.segment,
       sum(f.amount) AS as_was_revenue,
       (SELECT sum(f2.amount) FROM scd.fact_orders f2
          JOIN scd.dim_customer v ON v.customer_key = f2.customer_key
          JOIN scd.dim_customer c ON c.customer_id = v.customer_id AND c.is_current
        WHERE c.segment = d.segment) AS as_is_revenue
FROM scd.fact_orders f
JOIN scd.dim_customer d USING (customer_key)
GROUP BY d.segment
ORDER BY d.segment;
