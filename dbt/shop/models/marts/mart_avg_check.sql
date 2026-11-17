{{ config(materialized='view') }}

-- Средний чек по дням: макрос safe_divide разворачивается в SQL при компиляции.
select
    order_date,
    orders,
    revenue,
    {{ safe_divide('revenue', 'orders') }} as avg_check
from {{ ref('fct_daily_sales') }}
