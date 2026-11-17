-- Урок 4: оконные функции в работе дата-инженера.
SET client_min_messages = warning;

-- 1. Дедупликация: из повторных доставок одного события оставляем последнюю (row_number)
DROP TABLE IF EXISTS app_events_clean CASCADE;
CREATE TABLE app_events_clean AS
SELECT event_id, user_id, event_time, event_type
FROM (SELECT *, row_number() OVER (PARTITION BY event_id ORDER BY loaded_at DESC) AS rn
      FROM app_events) t
WHERE rn = 1;

-- 2. Сессии: новая сессия начинается, если пользователь молчал больше 30 минут (lag и нарастающая сумма)
CREATE OR REPLACE VIEW reports.sessions AS
WITH marked AS (
    SELECT user_id, event_time, event_type,
           CASE WHEN event_time - lag(event_time) OVER w > interval '30 minutes'
                  OR lag(event_time) OVER w IS NULL THEN 1 ELSE 0 END AS is_new
    FROM app_events_clean
    WINDOW w AS (PARTITION BY user_id ORDER BY event_time)
), numbered AS (
    SELECT *, sum(is_new) OVER (PARTITION BY user_id ORDER BY event_time ROWS UNBOUNDED PRECEDING) AS session_no
    FROM marked
)
SELECT user_id, session_no,
       min(event_time)                              AS started_at,
       max(event_time) - min(event_time)            AS duration,
       count(*)                                     AS events,
       count(*) FILTER (WHERE event_type = 'purchase') AS purchases
FROM numbered
GROUP BY user_id, session_no;

-- 3. Покупки по дням: нарастающий итог и скользящее среднее за 7 дней (агрегаты по окну с рамкой)
CREATE OR REPLACE VIEW reports.daily_purchases AS
SELECT day, purchases,
       sum(purchases) OVER (ORDER BY day ROWS UNBOUNDED PRECEDING)       AS purchases_to_date,
       round(avg(purchases) OVER (ORDER BY day ROWS 6 PRECEDING), 0)     AS avg_7d
FROM (SELECT event_time::date AS day, count(*) AS purchases
      FROM app_events_clean
      WHERE event_type = 'purchase' AND event_time < date '2025-12-01'   -- хвост визитов 30 ноября ушёл за полночь
      GROUP BY day) d;
