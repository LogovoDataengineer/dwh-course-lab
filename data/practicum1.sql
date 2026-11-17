-- Практикум L07: сырые выгрузки магазина «Полка» в слое STG. Всё текстом, как пришло из источников.
DROP SCHEMA IF EXISTS stg CASCADE; DROP SCHEMA IF EXISTS ods CASCADE; DROP SCHEMA IF EXISTS cdm CASCADE; DROP SCHEMA IF EXISTS meta CASCADE;
CREATE SCHEMA stg; CREATE SCHEMA ods; CREATE SCHEMA cdm; CREATE SCHEMA meta;
CREATE TABLE stg.customers_raw (customer_id text, full_name text, email text, city text, updated_at text, batch_id integer, load_dttm timestamp);
CREATE TABLE stg.orders_raw (order_id text, customer_id text, created_at text, status text, amount text, batch_id integer, load_dttm timestamp);
INSERT INTO stg.customers_raw VALUES
('1', 'Анна Смирнова', 'ANNA@example.ru ', 'Казань', '2026-03-01 09:00:00', 1, '2026-03-01 10:00'),
('2', 'Иван Петров', 'ivan@example.ru', 'москва', '2026-03-01 09:30:00', 1, '2026-03-01 10:00'),
('3', 'Ольга Кузнецова', '', 'Тверь', '2026-03-01 09:40:00', 1, '2026-03-01 10:00'),
('1', 'Анна Смирнова', 'anna@example.ru', 'Москва', '2026-03-02 08:00:00', 2, '2026-03-02 10:00'),
('4', 'Павел Волков', 'pavel@example.ru', 'Омск', '2026-03-02 08:30:00', 2, '2026-03-02 10:00');
INSERT INTO stg.orders_raw VALUES
('101', '1', '2026-03-01 10:15:00', 'created', '1190.00', 1, '2026-03-01 11:00'),
('102', '2', '2026-03-01 10:40:00', 'PAID', '890', 1, '2026-03-01 11:00'),
('103', '3', '2026-03-01 11:30:00', ' paid ', '6490.00', 1, '2026-03-01 11:00'),
('101', '1', '2026-03-01 10:15:00', 'paid', '1190.00', 2, '2026-03-02 11:00'),
('104', '9', '2026-03-02 09:00:00', 'paid', '300', 2, '2026-03-02 11:00'),
('105', '4', '2026-03-02 12:00:00', 'paid', 'n/a', 2, '2026-03-02 11:00'),
('106', '2', '2026-03-02 13:00:00', 'cancelled', '450.00', 2, '2026-03-02 11:00');
