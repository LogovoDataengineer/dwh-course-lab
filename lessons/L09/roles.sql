-- Урок 9: одно измерение дат в трёх ролях. Сколько заказов создано, оплачено и доставлено в каждый день недели.
SELECT d.full_date, to_char(d.full_date, 'Dy') AS dow,
       (SELECT count(*) FROM flow.fact_order_pipeline f WHERE f.created_date_key = d.date_key)   AS created,
       (SELECT count(*) FROM flow.fact_order_pipeline f WHERE f.paid_date_key = d.date_key)      AS paid,
       (SELECT count(*) FROM flow.fact_order_pipeline f WHERE f.delivered_date_key = d.date_key) AS delivered
FROM flow.dim_date d
WHERE d.full_date BETWEEN '2025-11-10' AND '2025-11-16'
ORDER BY d.full_date;
