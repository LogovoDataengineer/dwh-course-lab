-- Урок 18: ClickHouse читает топик clicks: очередь (движок Kafka, группа clickhouse) → материализованное
-- представление → таблица stream.clicks с номером партиции, offset'ом и временем записи сообщения в Kafka.
CREATE DATABASE IF NOT EXISTS stream;
CREATE TABLE stream.clicks_queue (event_id String, user_id UInt32, page String, event_time DateTime64(3, 'UTC'))
ENGINE = Kafka SETTINGS kafka_broker_list = 'kafka:9092', kafka_topic_list = 'clicks',
                        kafka_group_name = 'clickhouse', kafka_format = 'JSONEachRow';
CREATE TABLE stream.clicks (
    event_id        String,
    user_id         UInt32,
    page            LowCardinality(String),
    event_time      DateTime64(3, 'UTC'),   -- когда клик случился на устройстве
    kafka_time      DateTime64(3, 'UTC'),   -- когда сообщение записано в Kafka
    kafka_partition UInt8,
    kafka_offset    UInt64
) ENGINE = MergeTree ORDER BY (kafka_partition, kafka_offset);
CREATE MATERIALIZED VIEW stream.clicks_mv TO stream.clicks AS
SELECT event_id, user_id, page, event_time, _timestamp_ms AS kafka_time, _partition AS kafka_partition, _offset AS kafka_offset
FROM stream.clicks_queue;
