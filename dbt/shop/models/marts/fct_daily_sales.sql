{{ config(materialized='incremental', unique_key='order_date') }}

-- Выручка по дням. Инкрементально пересчитываются последние 3 дня от максимума в витрине:
-- статусы заказов меняются задним числом (окно перекрытия, урок L15).
select
    o.order_date,
    count(distinct o.order_id) as orders,
    sum(i.line_total)          as revenue
from {{ ref('stg_orders') }} o
join {{ ref('stg_order_items') }} i on i.order_id = o.order_id
where o.status <> 'cancelled'
{% if is_incremental() %}
  and o.order_date >= (select max(order_date) - 3 from {{ this }})
{% endif %}
group by o.order_date
