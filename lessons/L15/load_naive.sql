-- Урок 15: инкремент по watermark «как в учебнике»: забрать строки новее отметки, MERGE в ODS,
-- новая отметка — максимум updated_at загруженных строк. Переменная run — номер прогона (её ставит run.sh).
SELECT watermark AS wm FROM inc.load_state WHERE table_name = 'orders' \gset
CREATE TEMP TABLE delta AS
SELECT * FROM inc.src_orders WHERE updated_at > :'wm';
MERGE INTO inc.orders o USING delta d ON o.order_id = d.order_id
WHEN MATCHED THEN UPDATE SET customer_id = d.customer_id, status = d.status, amount = d.amount, updated_at = d.updated_at
WHEN NOT MATCHED THEN INSERT VALUES (d.order_id, d.customer_id, d.status, d.amount, d.updated_at);
UPDATE inc.load_state SET watermark = greatest(watermark, (SELECT max(updated_at) FROM delta)) WHERE table_name = 'orders';
INSERT INTO inc.load_log (run_id, watermark_before, watermark_after, rows_read)
SELECT :run, :'wm', watermark, (SELECT count(*) FROM delta) FROM inc.load_state WHERE table_name = 'orders';
