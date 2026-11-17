-- Урок 8: таблицы базы сайта видны в хранилище через postgres_fdw (схема src базы dwh).
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_foreign_server WHERE srvname = 'shop_src') THEN
    CREATE SERVER shop_src FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'shop', fetch_size '50000');
    CREATE USER MAPPING FOR dwh SERVER shop_src OPTIONS (user 'dwh', password 'dwh');
  END IF;
END $$;
-- сервер мог остаться от урока 5: строки забираем пачками по 50 000, а не по 100 (по умолчанию)
DO $$ BEGIN
  ALTER SERVER shop_src OPTIONS (ADD fetch_size '50000');
EXCEPTION WHEN duplicate_object THEN
  ALTER SERVER shop_src OPTIONS (SET fetch_size '50000');
END $$;
DROP SCHEMA IF EXISTS src CASCADE;
CREATE SCHEMA src;
IMPORT FOREIGN SCHEMA public LIMIT TO (sales_history, product_catalog) FROM SERVER shop_src INTO src;
DROP SCHEMA IF EXISTS mart CASCADE;
CREATE SCHEMA mart;
