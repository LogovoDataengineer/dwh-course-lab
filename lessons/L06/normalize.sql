-- Урок 6: плоская выгрузка в третьей нормальной форме. Правила для противоречий записаны явно:
-- город покупателя и название товара — из самой поздней строки, дата заказа — самая ранняя,
-- строки заказа нумеруются: один товар может встретиться в заказе дважды.
SET client_min_messages = warning;
DROP TABLE IF EXISTS norm.order_items, norm.orders, norm.customers, norm.products, norm.categories CASCADE;

CREATE TABLE norm.categories (category_id serial PRIMARY KEY, category text NOT NULL UNIQUE);
INSERT INTO norm.categories (category) SELECT DISTINCT category FROM norm.sales_flat ORDER BY category;

CREATE TABLE norm.products (
    product_id   integer PRIMARY KEY,
    product_name text    NOT NULL,
    category_id  integer NOT NULL REFERENCES norm.categories
);
INSERT INTO norm.products
SELECT DISTINCT ON (f.product_id) f.product_id, f.product_name, c.category_id
FROM norm.sales_flat f JOIN norm.categories c USING (category)
ORDER BY f.product_id, f.order_date DESC;

CREATE TABLE norm.customers (
    customer_id   integer PRIMARY KEY,
    customer_name text NOT NULL,
    customer_city text NOT NULL
);
INSERT INTO norm.customers
SELECT DISTINCT ON (customer_id) customer_id, customer_name, customer_city
FROM norm.sales_flat
ORDER BY customer_id, order_date DESC, order_id DESC;

CREATE TABLE norm.orders (
    order_id    integer PRIMARY KEY,
    order_date  date    NOT NULL,
    customer_id integer NOT NULL REFERENCES norm.customers
);
INSERT INTO norm.orders
SELECT order_id, min(order_date), min(customer_id) FROM norm.sales_flat GROUP BY order_id;

CREATE TABLE norm.order_items (
    order_id   integer NOT NULL REFERENCES norm.orders,
    line_no    integer NOT NULL,
    product_id integer NOT NULL REFERENCES norm.products,
    quantity   integer NOT NULL CHECK (quantity > 0),
    price      numeric(10, 2) NOT NULL CHECK (price >= 0),
    PRIMARY KEY (order_id, line_no)
);
INSERT INTO norm.order_items
SELECT order_id, row_number() OVER (PARTITION BY order_id ORDER BY product_id, price), product_id, quantity, price
FROM norm.sales_flat;

ANALYZE norm.categories, norm.products, norm.customers, norm.orders, norm.order_items;
SELECT (SELECT count(*) FROM norm.categories) AS categories, (SELECT count(*) FROM norm.products) AS products,
       (SELECT count(*) FROM norm.customers) AS customers, (SELECT count(*) FROM norm.orders) AS orders,
       (SELECT count(*) FROM norm.order_items) AS order_items;
