{% snapshot customers_snapshot %}
{{ config(target_schema='snapshots', unique_key='customer_id', strategy='check', check_cols=['full_name', 'city']) }}
select customer_id, full_name, city from {{ source('shop', 'customers') }}
{% endsnapshot %}
