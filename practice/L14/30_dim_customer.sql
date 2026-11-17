-- Урок 14, модель «Полки». Шаг 3: покупатели, SCD2 по городу из истории CRM.
-- Версия действует в [valid_from, valid_to); ключ 0 — неизвестный покупатель.
CREATE TABLE polka.dim_customer (
    customer_key integer PRIMARY KEY,
    customer_id  integer,
    full_name    text,
    city         text,
    valid_from   timestamp,
    valid_to     timestamp,
    is_current   boolean
);
INSERT INTO polka.dim_customer VALUES (0, NULL, 'неизвестный покупатель', 'неизвестно', '1900-01-01', '9999-12-31', true);
INSERT INTO polka.dim_customer
SELECT row_number() OVER (ORDER BY h.customer_id, h.changed_at),
       h.customer_id, c.full_name, h.city,
       h.changed_at,
       coalesce(lead(h.changed_at) OVER w, '9999-12-31'),
       lead(h.changed_at) OVER w IS NULL
FROM polka_stg.city_history h
JOIN polka_stg.customers c ON c.customer_id = h.customer_id
WINDOW w AS (PARTITION BY h.customer_id ORDER BY h.changed_at);
CREATE INDEX ON polka.dim_customer (customer_id, valid_from);
ANALYZE polka.dim_customer;
