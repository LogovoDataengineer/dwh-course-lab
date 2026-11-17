-- Урок 5: источник — старая учётная система заказов «Полки». Она хранит всё строками и отдаёт
-- заказы, изменённые за последние сутки. Часы источника (legacy_clock) двигает tick.sql.
SET client_min_messages = warning;
DROP TABLE IF EXISTS legacy_orders, legacy_clock;
CREATE TABLE legacy_clock (now_at timestamp NOT NULL, tick integer NOT NULL);
INSERT INTO legacy_clock VALUES ('2026-03-01 09:00', 0);
CREATE TABLE legacy_orders (
    order_id    text PRIMARY KEY,
    customer_id text,
    created_at  text,
    status      text,
    amount      text,
    updated_at  timestamp NOT NULL
);
