select
    order_id,
    customer_id,
    created_at,
    created_at::date as order_date,
    lower(status)    as status,
    updated_at
from {{ source('shop', 'orders') }}
