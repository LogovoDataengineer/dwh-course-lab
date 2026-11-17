select
    order_id,
    product_id,
    quantity,
    price,
    quantity * price as line_total
from {{ source('shop', 'order_items') }}
