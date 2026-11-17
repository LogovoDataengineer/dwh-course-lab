-- Урок 8: справочник товаров в базе сайта. Пять новых товаров продаются,
-- но в справочник ещё не внесены — для них понадобится неизвестный член измерения.
SET client_min_messages = warning;
DROP TABLE IF EXISTS product_catalog;
CREATE TABLE product_catalog (product_id integer PRIMARY KEY, product_name text NOT NULL, category text NOT NULL, brand text NOT NULL);
INSERT INTO product_catalog
SELECT p, (ARRAY['Книга','Гаджет','Товар для дома','Спорттовар','Игрушка'])[1 + (p - 1) / 1000] || ' №' || p,
       (ARRAY['Книги','Электроника','Дом','Спорт','Игрушки'])[1 + (p - 1) / 1000],
       (ARRAY['Полка','Северный ветер','Домовой','Старт','Карусель','Эксмо','Технолайн'])[1 + p % 7]
FROM generate_series(1, 5000) p
WHERE p NOT IN (777, 1777, 2777, 3777, 4777);
