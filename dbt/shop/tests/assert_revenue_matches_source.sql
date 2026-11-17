-- Сверка: выручка витрины равна выручке в источнике. Тест падает, если запрос вернул строки.
with mart as (select sum(revenue) as revenue from {{ ref('fct_daily_sales') }}),
src as (
    select sum(i.quantity * i.price) as revenue
    from {{ source('shop', 'orders') }} o
    join {{ source('shop', 'order_items') }} i on i.order_id = o.order_id
    where o.status <> 'cancelled'
)
select mart.revenue as mart_revenue, src.revenue as source_revenue
from mart, src
where mart.revenue <> src.revenue
