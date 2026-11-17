-- Урок 12: bridge строк заказа — цепочка «заказ — покупатель — товар» из двух линков, соединённая заранее.
-- Пересобирается после каждой загрузки.
SET client_min_messages = warning;
DROP TABLE IF EXISTS dv.bridge_order_line;
CREATE TABLE dv.bridge_order_line AS
SELECT lp.hk_order_product, lp.hk_order, lc.hk_customer, lp.hk_product
FROM dv.link_order_product lp
JOIN dv.link_order_customer lc ON lc.hk_order = lp.hk_order;
ALTER TABLE dv.bridge_order_line ADD PRIMARY KEY (hk_order_product);
ANALYZE dv.bridge_order_line;
