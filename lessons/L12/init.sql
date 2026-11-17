-- Урок 12: призрачные записи (ghost records) в сателлитах покупателя и пустые PIT и bridge.
SET client_min_messages = warning;
INSERT INTO dv.sat_customer VALUES (repeat('0', 32), '1900-01-01', repeat('0', 32), NULL, NULL, NULL, 'SYSTEM') ON CONFLICT DO NOTHING;
INSERT INTO dv.sat_customer_loyalty VALUES (repeat('0', 32), '1900-01-01', repeat('0', 32), NULL, NULL, 'SYSTEM') ON CONFLICT DO NOTHING;
DROP TABLE IF EXISTS dv.pit_customer, dv.bridge_order_line;
CREATE TABLE dv.pit_customer (
    hk_customer   char(32) NOT NULL,
    snapshot_date date NOT NULL,
    site_hk       char(32) NOT NULL,   -- версия в sat_customer (сайт)
    site_ldts     timestamp NOT NULL,
    crm_hk        char(32) NOT NULL,   -- версия в sat_customer_loyalty (CRM)
    crm_ldts      timestamp NOT NULL,
    PRIMARY KEY (hk_customer, snapshot_date)
);
