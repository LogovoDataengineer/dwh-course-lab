-- Урок 14, модель «Полки». Шаг 2: товары, SCD1, категория прямо в измерении (звезда, а не снежинка).
-- Ключ 0 — неизвестный член: на него сошлются строки заказов, чьих товаров нет в каталоге.
CREATE TABLE polka.dim_product (
    product_key   integer PRIMARY KEY,
    product_id    integer UNIQUE,
    product_name  text,
    category      text,
    current_price numeric(10, 2)
);
INSERT INTO polka.dim_product VALUES (0, NULL, 'неизвестный товар', 'неизвестно', NULL);
INSERT INTO polka.dim_product
SELECT row_number() OVER (ORDER BY p.product_id), p.product_id, p.name, c.name, p.price
FROM polka_stg.products p
JOIN polka_stg.categories c ON c.category_id = p.category_id;
