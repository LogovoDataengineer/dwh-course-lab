-- Урок 15: полная загрузка — вся таблица источника заново в ODS, отметка — максимум updated_at.
\timing on
TRUNCATE inc.orders;
INSERT INTO inc.orders SELECT * FROM inc.src_orders;
UPDATE inc.load_state SET watermark = (SELECT max(updated_at) FROM inc.orders) WHERE table_name = 'orders';
