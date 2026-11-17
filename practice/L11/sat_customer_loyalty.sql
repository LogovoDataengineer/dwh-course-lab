-- Урок 11, шаг 7: новый источник — программа лояльности из старой CRM (stage_dv.loyalty_cards).
-- В Data Vault новый источник не меняет существующие таблицы: у хаба покупателей появляется ещё один сателлит.
-- Таблица уже описана ниже. Допишите загрузку: новая строка, если уровень или баллы изменились
-- по сравнению с последней версией (или версий ещё нет); record_source = 'crm'; load_dts = :'load_dts'.
-- ВНИМАНИЕ: client_ref — номер покупателя текстом, с нулями слева и иногда с пробелами ('0000042 ').
-- Хеш-ключ должен совпасть с хабом: hk_customer = md5('42').
-- Файл выполняется вместе с остальными заданиями загрузки: bash lessons/L11/load.sh
CREATE TABLE IF NOT EXISTS dv.sat_customer_loyalty (
    hk_customer   char(32) NOT NULL,
    load_dts      timestamp NOT NULL,
    hashdiff      char(32) NOT NULL,
    tier          text,
    points        integer,
    record_source text NOT NULL,
    PRIMARY KEY (hk_customer, load_dts)
);

-- INSERT INTO dv.sat_customer_loyalty (...)
-- SELECT ...
