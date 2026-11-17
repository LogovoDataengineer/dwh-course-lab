select
    c.customer_id,
    c.full_name,
    c.city,
    count(distinct o.order_id) filter (where o.status <> 'cancelled') as orders
from {{ ref('stg_customers') }} c
left join {{ ref('stg_orders') }} o on o.customer_id = c.customer_id
group by c.customer_id, c.full_name, c.city
