-- Урок 12: выручка по категориям товаров и уровню лояльности покупателя на последний день — bridge + PIT.
\timing on
SELECT pr.category, coalesce(l.tier, 'без карты') AS tier, sum(op.quantity * op.price) AS revenue
FROM dv.bridge_order_line b
JOIN (SELECT DISTINCT ON (hk_order_product) hk_order_product, quantity, price
      FROM dv.sat_order_product ORDER BY hk_order_product, load_dts DESC) op ON op.hk_order_product = b.hk_order_product
JOIN (SELECT DISTINCT ON (hk_product) hk_product, category
      FROM dv.sat_product ORDER BY hk_product, load_dts DESC) pr ON pr.hk_product = b.hk_product
JOIN dv.pit_customer p ON p.hk_customer = b.hk_customer AND p.snapshot_date = (SELECT max(snapshot_date) FROM dv.pit_customer)
JOIN dv.sat_customer_loyalty l ON l.hk_customer = p.crm_hk AND l.load_dts = p.crm_ldts
GROUP BY 1, 2
ORDER BY 1, 2;
