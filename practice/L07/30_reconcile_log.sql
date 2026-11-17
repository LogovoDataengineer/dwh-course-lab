-- Шаги 3–4. Сверка слоёв и журнал: каждый заказ из STG — ровно в одном месте, ODS или отбраковке.
INSERT INTO meta.load_log (batch_id, target, rows_loaded, rows_rejected, lost)
SELECT :batch, 'ods.orders',
       (SELECT count(*) FROM ods.orders),
       (SELECT count(*) FROM ods.orders_rejected),
       (SELECT count(DISTINCT order_id) FROM stg.orders_raw) - (SELECT count(*) FROM ods.orders) - (SELECT count(*) FROM ods.orders_rejected);
-- если что-то потерялось, загрузка останавливается с ошибкой: витрину по неполным данным не строим
DO $$ BEGIN
  IF (SELECT lost FROM meta.load_log ORDER BY loaded_at DESC LIMIT 1) <> 0 THEN
    RAISE EXCEPTION 'сверка STG и ODS не сошлась: заказы потерялись';
  END IF;
END $$;
