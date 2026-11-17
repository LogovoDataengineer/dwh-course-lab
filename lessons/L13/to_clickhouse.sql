-- Урок 13: факт поездок в ClickHouse — колоночная таблица, отсортированная по дате и городу.
CREATE DATABASE IF NOT EXISTS taxi;
CREATE OR REPLACE TABLE taxi.fact_trips (
    trip_id UInt32, started_at DateTime, trip_date Date, city LowCardinality(String),
    rider_id UInt32, driver_id UInt32, car_class LowCardinality(String), status LowCardinality(String),
    distance_km Decimal(6, 1), surge Decimal(3, 1), price Decimal(10, 2),
    bonus_amount Decimal(10, 2), card_amount Decimal(10, 2)
) ENGINE = MergeTree ORDER BY (trip_date, city, trip_id);
INSERT INTO taxi.fact_trips
SELECT * FROM postgresql('postgres:5432', 'shop', 'v_fact_trips', 'dwh', 'dwh', 'taxi');
SELECT count() AS trips, sum(price) AS price_total, sum(bonus_amount) AS bonus_total,
       (SELECT formatReadableSize(sum(data_compressed_bytes)) FROM system.columns
        WHERE database = 'taxi' AND table = 'fact_trips') AS on_disk
FROM taxi.fact_trips;
