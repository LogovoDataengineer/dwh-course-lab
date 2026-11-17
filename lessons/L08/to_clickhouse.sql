-- Урок 8: та же звезда в ClickHouse. Таблицы копируются из хранилища табличной функцией postgresql().
CREATE DATABASE IF NOT EXISTS mart;
CREATE OR REPLACE TABLE mart.dim_date ENGINE = MergeTree ORDER BY date_key
AS SELECT * FROM postgresql('postgres:5432', 'dwh', 'dim_date', 'dwh', 'dwh', 'mart');
CREATE OR REPLACE TABLE mart.dim_product ENGINE = MergeTree ORDER BY product_key
AS SELECT * FROM postgresql('postgres:5432', 'dwh', 'dim_product', 'dwh', 'dwh', 'mart');
CREATE OR REPLACE TABLE mart.fact_sales ENGINE = MergeTree ORDER BY (date_key, product_key)
AS SELECT * FROM postgresql('postgres:5432', 'dwh', 'fact_sales', 'dwh', 'dwh', 'mart');
SELECT count() AS fact_rows FROM mart.fact_sales;
