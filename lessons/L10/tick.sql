-- Урок 10: проходит день в CRM. Меняется 1% покупателей: переезд, повышение сегмента, исправление email;
-- приходят 100 новых покупателей и около 1500 заказов этого дня.
SET client_min_messages = warning;
UPDATE crm_clock SET today = today + 1;
SELECT setseed(extract(doy FROM today) / 1000.0) FROM crm_clock \g /dev/null
UPDATE crm_customers SET city = (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 5)::int]
WHERE random() < 0.004;
UPDATE crm_customers SET segment = CASE segment WHEN 'new' THEN 'silver' WHEN 'silver' THEN 'gold' ELSE 'gold' END
WHERE random() < 0.004;
UPDATE crm_customers SET email = 'u' || customer_id || '.fixed' || (SELECT extract(doy FROM today)::int FROM crm_clock) || '@mail.example'
WHERE random() < 0.003;
INSERT INTO crm_customers
SELECT m + n, 'Покупатель ' || (m + n), (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 5)::int],
       'new', 'user' || (m + n) || '@mail.example'
FROM (SELECT max(customer_id) AS m FROM crm_customers) x, generate_series(1, 100) AS n;
INSERT INTO crm_orders (customer_id, order_date, amount)
SELECT 1 + floor(random() * (SELECT max(customer_id) FROM crm_customers))::int, c.today,
       round((300 + random() * 9000)::numeric, -1)
FROM crm_clock c, generate_series(1, 1500);
