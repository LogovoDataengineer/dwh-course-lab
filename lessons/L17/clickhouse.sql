-- Урок 17: ClickHouse читает топик shop.cdc.orders сам — таблица на движке Kafka и материализованное
-- представление, которое раскладывает каждое событие Debezium по столбцам в таблицу cdc.order_events.
CREATE DATABASE IF NOT EXISTS cdc;
DROP TABLE IF EXISTS cdc.orders_mv;
DROP TABLE IF EXISTS cdc.orders_queue;
DROP TABLE IF EXISTS cdc.order_events;
CREATE TABLE cdc.orders_queue (raw String)
ENGINE = Kafka SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'shop.cdc.orders',
                        kafka_group_name = 'clickhouse_cdc', kafka_format = 'JSONAsString';
CREATE TABLE cdc.order_events (
    order_id     UInt64,
    op           LowCardinality(String),   -- r снимок, c вставка, u изменение, d удаление
    lsn          UInt64,                   -- позиция изменения в журнале PostgreSQL
    kafka_offset UInt64,
    customer_id  Nullable(UInt32),
    status       Nullable(String),
    amount       Nullable(Decimal(10, 2)),
    updated_at   Nullable(DateTime64(3)),
    raw          String
) ENGINE = MergeTree ORDER BY (order_id, lsn, kafka_offset);
CREATE MATERIALIZED VIEW cdc.orders_mv TO cdc.order_events AS
SELECT JSONExtractUInt(data, 'order_id') AS order_id, op,
       JSONExtractUInt(raw, 'source', 'lsn') AS lsn, _offset AS kafka_offset,
       if(op = 'd', NULL, JSONExtractUInt(data, 'customer_id')) AS customer_id,
       if(op = 'd', NULL, JSONExtractString(data, 'status')) AS status,
       if(op = 'd', NULL, toDecimal64(JSONExtractString(data, 'amount'), 2)) AS amount,
       if(op = 'd', NULL, parseDateTime64BestEffortOrNull(JSONExtractString(data, 'updated_at'), 3)) AS updated_at,
       raw
FROM (SELECT raw, JSONExtractString(raw, 'op') AS op,
             if(op = 'd', JSONExtractRaw(raw, 'before'), JSONExtractRaw(raw, 'after')) AS data, _offset
      FROM cdc.orders_queue);
