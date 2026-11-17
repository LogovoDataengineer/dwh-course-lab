select customer_id, full_name, city, updated_at
from {{ source('shop', 'customers') }}
