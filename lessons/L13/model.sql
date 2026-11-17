-- Урок 13: факт поездок в зерне «одна поездка». Оплаты сведены до поездки (бонусы и карта — отдельные меры),
-- класс автомобиля — тот, что был у водителя в момент поездки (SCD2), а не текущий.
CREATE OR REPLACE VIEW taxi.v_fact_trips AS
WITH paid AS (
    SELECT trip_id,
           coalesce(sum(amount) FILTER (WHERE method = 'bonus'), 0) AS bonus_amount,
           coalesce(sum(amount) FILTER (WHERE method = 'card'), 0)  AS card_amount
    FROM taxi.trip_payments GROUP BY trip_id
)
SELECT t.trip_id, t.started_at, t.started_at::date AS trip_date, t.city, t.rider_id, t.driver_id, h.car_class,
       t.status, t.distance_km, t.surge, t.price,
       coalesce(p.bonus_amount, 0) AS bonus_amount, coalesce(p.card_amount, 0) AS card_amount
FROM taxi.trips t
JOIN taxi.driver_class_history h ON h.driver_id = t.driver_id
                                AND t.started_at >= h.valid_from AND t.started_at < h.valid_to
LEFT JOIN paid p ON p.trip_id = t.trip_id;
