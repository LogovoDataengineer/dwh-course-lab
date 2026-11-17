-- Урок 4: журнал событий приложения «Полки» за ноябрь 2025 — сырые данные, как они приходят из трекера.
-- Около 2% событий пришли дважды (трекер повторил отправку): тот же event_id, позже loaded_at.
SET client_min_messages = warning;
CREATE TABLE IF NOT EXISTS app_events (
    event_id   bigint      NOT NULL,
    user_id    integer     NOT NULL,
    event_time timestamp   NOT NULL,
    event_type text        NOT NULL,
    loaded_at  timestamp   NOT NULL
);
SELECT setseed(0.77) \g /dev/null
INSERT INTO app_events
WITH visits AS (          -- визит: пользователь заходит и делает несколько действий подряд
    -- в выходные заходят чаще: будни принимаем с вероятностью 0,65, выходные — всегда
    SELECT row_number() OVER () AS visit_id, user_id, started_at, actions
    FROM (SELECT 1 + floor(random() * 20000)::int AS user_id,
                 date_trunc('second', timestamp '2025-11-01' + floor(random() * 30) * interval '1 day'
                                                + random() * interval '1 day') AS started_at,
                 2 + floor(random() * 12)::int AS actions,
                 random() AS r
          FROM generate_series(1, 200000)
          WHERE NOT EXISTS (SELECT 1 FROM app_events)) c
    WHERE extract(isodow FROM started_at) IN (6, 7) OR r < 0.65
), events AS (
    SELECT row_number() OVER (ORDER BY v.visit_id, a) AS event_id,
           v.user_id,
           v.started_at + (a * 90 + floor(random() * 60)) * interval '1 second' AS event_time,
           CASE WHEN a = 1 THEN 'open'
                WHEN a = v.actions AND random() < 0.3 THEN 'purchase'
                WHEN random() < 0.25 THEN 'cart'
                ELSE 'view' END AS event_type
    FROM visits v, generate_series(1, v.actions) AS a
)
SELECT event_id, user_id, event_time, event_type, event_time + interval '2 minutes' FROM events
UNION ALL
SELECT event_id, user_id, event_time, event_type, event_time + interval '15 minutes'   -- повторная доставка
FROM events WHERE event_id % 50 = 7;
CREATE INDEX IF NOT EXISTS app_events_user_time ON app_events (user_id, event_time);
ANALYZE app_events;
SELECT count(*) AS events, count(DISTINCT event_id) AS unique_events, count(DISTINCT user_id) AS users FROM app_events;
