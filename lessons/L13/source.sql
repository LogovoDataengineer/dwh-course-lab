-- Урок 13: сервис такси — источник для задачи «спроектируйте хранилище». Схема taxi в базе сайта:
-- водители и их класс автомобиля (SCD2), 2 миллиона поездок за 12 недель, оплаты (часть поездок — двумя способами).
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS taxi CASCADE;
CREATE SCHEMA taxi;
SELECT setseed(0.1313) \g /dev/null

CREATE TABLE taxi.drivers AS
SELECT d AS driver_id, 'Водитель ' || d AS full_name,
       (ARRAY['Москва','Москва','Москва','Санкт-Петербург','Санкт-Петербург','Казань','Екатеринбург'])[1 + d % 7] AS city
FROM generate_series(1, 3000) AS d;
ALTER TABLE taxi.drivers ADD PRIMARY KEY (driver_id);

-- класс автомобиля меняется: 15% водителей пересаживаются с эконома на комфорт в середине периода
CREATE TABLE taxi.driver_class_history (driver_id integer NOT NULL, car_class text NOT NULL, valid_from date NOT NULL, valid_to date NOT NULL);
INSERT INTO taxi.driver_class_history
SELECT driver_id, cls, '2025-01-01', CASE WHEN upgrade THEN switch ELSE '9999-12-31' END
FROM (SELECT driver_id, CASE WHEN random() < 0.25 THEN 'комфорт' ELSE 'эконом' END AS cls, random() < 0.15 AS upgrade,
             date '2026-01-05' + floor(random() * 84)::int AS switch FROM taxi.drivers) d;
INSERT INTO taxi.driver_class_history
SELECT h.driver_id, 'комфорт', h.valid_to, '9999-12-31' FROM taxi.driver_class_history h WHERE h.valid_to < '9999-12-31';
UPDATE taxi.driver_class_history SET car_class = 'эконом' WHERE valid_to < '9999-12-31';

-- поездки: 12 недель с 5 января 2026; новые пассажиры приходят каждый день, старые постепенно уходят
CREATE TABLE taxi.trips AS
SELECT t AS trip_id,
       1 + floor(r_max * (1 - random() ^ 6))::int AS rider_id,
       driver_id, city, started_at, distance_km, surge,
       round(((CASE WHEN cls = 'комфорт' THEN 140 ELSE 99 END) + distance_km * (CASE WHEN cls = 'комфорт' THEN 24 ELSE 17 END)) * surge, 0) AS price,
       CASE WHEN random() < 0.08 THEN 'cancelled' ELSE 'completed' END AS status
FROM (
  SELECT t, s.started_at, d.driver_id, d.city, h.car_class AS cls,
         greatest(0.8, round((exp(random() * 3.4) * 0.9)::numeric, 1)) AS distance_km,
         (CASE WHEN random() < 0.15 THEN 1.3 + floor(random() * 4) / 5 ELSE 1.0 END)::numeric(3, 1) AS surge,
         30000 + 370000 * extract(epoch FROM s.started_at - '2026-01-05') / (84 * 86400) AS r_max
  FROM generate_series(1, 2000000) AS t
  CROSS JOIN LATERAL (SELECT timestamp '2026-01-05' + ((t - 1) / 2000000.0 * 83.99 + random() * 0.01) * interval '1 day' AS started_at,
                             1 + floor(random() * 3000)::int AS driver_id) s
  JOIN taxi.drivers d ON d.driver_id = s.driver_id
  JOIN taxi.driver_class_history h ON h.driver_id = d.driver_id
                                  AND s.started_at >= h.valid_from AND s.started_at < h.valid_to
) x;
ALTER TABLE taxi.trips ADD PRIMARY KEY (trip_id);

-- оплаты: обычно картой; 12% поездок — частично бонусами, остаток картой (две строки); отменённые не оплачены
CREATE TABLE taxi.trip_payments (payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, trip_id integer NOT NULL,
                                 amount numeric(10, 2) NOT NULL, method text NOT NULL);
CREATE TEMP TABLE split AS
SELECT trip_id, price, CASE WHEN random() < 0.12 THEN least(price - 1, 50 + floor(random() * 300)) END AS bonus
FROM taxi.trips WHERE status = 'completed';
INSERT INTO taxi.trip_payments (trip_id, amount, method)
SELECT trip_id, bonus, 'bonus' FROM split WHERE bonus IS NOT NULL
UNION ALL
SELECT trip_id, price - coalesce(bonus, 0), 'card' FROM split;
CREATE INDEX ON taxi.trip_payments (trip_id);
ANALYZE taxi.drivers, taxi.driver_class_history, taxi.trips, taxi.trip_payments;
