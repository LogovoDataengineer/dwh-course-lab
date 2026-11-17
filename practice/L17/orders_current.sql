-- Урок 17, шаг 5 (ваш): текущее состояние заказов из потока событий Debezium — представление cdc.orders_current.
-- Столбцы, порядок важен: order_id, customer_id, status, amount, updated_at
-- В cdc.order_events на каждый заказ лежат все его события: снимок (op = 'r'), вставка ('c'), изменения ('u'),
-- удаление ('d'). Возьмите для каждого заказа ПОСЛЕДНЕЕ событие — по позиции в журнале lsn, а при равных lsn
-- по kafka_offset. Если последнее событие — удаление, заказа в текущем состоянии быть не должно.
-- Подсказка: argMax(значение, (lsn, kafka_offset)) возвращает значение из строки с наибольшим ключом.
-- Выполнить: make ch F=practice/L17/orders_current.sql     Сверить: make ch F=lessons/L17/reconcile.sql
CREATE OR REPLACE VIEW cdc.orders_current AS
SELECT ...
