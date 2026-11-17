-- Урок 8: таблица фактов. Зерно — одна продажа (строка sales_history). Меры — количество и сумма,
-- ссылки на измерения — суррогатные ключи; ненайденное измерение получает -1, строка не теряется.
SET client_min_messages = warning;
DROP TABLE IF EXISTS mart.fact_sales;
CREATE TABLE mart.fact_sales (
    sale_id      bigint PRIMARY KEY,                       -- вырожденное измерение: номер из источника
    date_key     integer NOT NULL,
    product_key  integer NOT NULL,
    customer_key integer NOT NULL,
    status       text NOT NULL,
    quantity     integer NOT NULL,
    amount       numeric(12, 2) NOT NULL
);
INSERT INTO mart.fact_sales
SELECT s.sale_id,
       to_char(s.sold_at, 'YYYYMMDD')::integer,
       coalesce(p.product_key, -1),
       coalesce(c.customer_key, -1),
       s.status,
       s.quantity,
       s.quantity * s.price
FROM src.sales_history s
LEFT JOIN mart.dim_product  p ON p.product_id  = s.product_id
LEFT JOIN mart.dim_customer c ON c.customer_id = s.customer_id;
-- внешние ключи — после загрузки: одна проверка всей таблицы быстрее, чем проверка каждой вставленной строки
ALTER TABLE mart.fact_sales
    ADD FOREIGN KEY (date_key)     REFERENCES mart.dim_date,
    ADD FOREIGN KEY (product_key)  REFERENCES mart.dim_product,
    ADD FOREIGN KEY (customer_key) REFERENCES mart.dim_customer;
ANALYZE mart.fact_sales;

-- Сверка с источником: столько же строк и та же сумма, плюс сколько строк ушло в неизвестный товар
SELECT (SELECT count(*) FROM src.sales_history) AS source_rows,
       (SELECT count(*) FROM mart.fact_sales) AS fact_rows,
       (SELECT sum(quantity * price) FROM src.sales_history) - (SELECT sum(amount) FROM mart.fact_sales) AS amount_diff,
       (SELECT count(*) FROM mart.fact_sales WHERE product_key = -1) AS unknown_product_rows;
