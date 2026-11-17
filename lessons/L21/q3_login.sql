-- Приложение, вход: покупатель по email без учёта регистра.
\set cid random(1, 300000)
SELECT customer_id, city FROM perf.customers WHERE lower(email) = lower('user' || :cid || '@mail.ru');
