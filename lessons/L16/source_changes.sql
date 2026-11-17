-- Урок 16: задним числом в источнике. Служба безопасности нашла мошеннические заказы: их УДАЛИЛИ из базы
-- магазина (в четырёх днях), а по одному дню бухгалтерия провела корректировку сумм.
SET client_min_messages = warning;
SELECT setseed(0.6161) \g /dev/null
DELETE FROM rel.sales WHERE sold_at::date IN ('2026-02-03', '2026-02-11', '2026-02-12', '2026-02-20') AND random() < 0.02;
UPDATE rel.sales SET amount = amount - 10 WHERE sold_at::date = '2026-02-17' AND random() < 0.1;
