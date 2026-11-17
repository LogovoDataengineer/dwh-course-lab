-- Урок 15, шаг 6 (ваш): инкремент по watermark, который не теряет строки длинных транзакций.
-- Переменная run — номер прогона, её ставит run.sh.
-- Сейчас это копия lessons/L15/load_naive.sql. Измените её так, чтобы прогон bash lessons/L15/run.sh practice/L15/load_orders.sql 40
-- закончился сверкой без расхождений, а каждая загрузка по-прежнему читала из источника только свежие строки:
--   ЗАДАНИЕ: забирайте строки с окном перекрытия — новее отметки минус запас, больший самой длинной транзакции
--   приложения. Строки из окна прочитаются повторно; MERGE запишет их ещё раз, и это безопасно.
SELECT watermark AS wm FROM inc.load_state WHERE table_name = 'orders' \gset
CREATE TEMP TABLE delta AS
SELECT * FROM inc.src_orders WHERE updated_at > :'wm';
MERGE INTO inc.orders o USING delta d ON o.order_id = d.order_id
WHEN MATCHED THEN UPDATE SET customer_id = d.customer_id, status = d.status, amount = d.amount, updated_at = d.updated_at
WHEN NOT MATCHED THEN INSERT VALUES (d.order_id, d.customer_id, d.status, d.amount, d.updated_at);
UPDATE inc.load_state SET watermark = greatest(watermark, (SELECT max(updated_at) FROM delta)) WHERE table_name = 'orders';
INSERT INTO inc.load_log (run_id, watermark_before, watermark_after, rows_read)
SELECT :run, :'wm', watermark, (SELECT count(*) FROM delta) FROM inc.load_state WHERE table_name = 'orders';
