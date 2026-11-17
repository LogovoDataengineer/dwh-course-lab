-- Урок 18: опоздавшие события — пришли в Kafka позже, чем через минуту после конца своего минутного окна.
SELECT count() AS events,
       countIf(kafka_time > toStartOfMinute(event_time) + INTERVAL 2 MINUTE) AS late_events,
       round(100 * late_events / events, 1) AS late_pct,
       max(dateDiff('second', event_time, kafka_time)) AS max_delay_sec
FROM (SELECT event_id, any(event_time) AS event_time, min(kafka_time) AS kafka_time FROM stream.clicks GROUP BY event_id);
