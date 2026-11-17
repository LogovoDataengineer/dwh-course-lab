-- Урок 13: выручка по городам в лоб (поездки JOIN оплаты) и правильно — оплаты сначала сводятся к зерну поездки.
\timing on
SELECT t.city, sum(t.price) AS revenue_wrong
FROM taxi.trips t JOIN taxi.trip_payments p ON p.trip_id = t.trip_id
WHERE t.status = 'completed'
GROUP BY t.city ORDER BY t.city;

SELECT city, sum(price) AS revenue
FROM taxi.trips WHERE status = 'completed'
GROUP BY city ORDER BY city;
