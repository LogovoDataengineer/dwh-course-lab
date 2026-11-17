-- Урок 19, шаг 6 (ваш): таблица оплат под запрос из шага 5 — mpp.payments_opt.
-- Те же столбцы и строки, что в mpp.payments: payment_id, order_id, paid_at, method, amount
-- (оплаты — с 1 января по 31 марта 2026 года). Нужно три решения:
--   1) ключ распределения — такой, чтобы соединение с mpp.orders шло без пересылки оплат между сегментами;
--   2) хранение — колоночная append-optimized таблица со сжатием zstd (appendonly = true, orientation = column);
--   3) партиции по месяцам по paid_at — запрос за февраль должен читать одну партицию.
-- Затем вставьте в неё все строки mpp.payments и выполните ANALYZE.
-- Выполнить: make gp F=practice/L19/payments_opt.sql     Сравнить план: make gp F=lessons/L19/join_plan_opt.sql
CREATE TABLE mpp.payments_opt ...
