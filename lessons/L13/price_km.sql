-- Урок 13: цена километра двумя способами — среднее отношений и отношение сумм.
SELECT city, car_class,
       round(avg(price / distance_km), 2)      AS avg_of_ratios,
       round(sum(price) / sum(distance_km), 2) AS ratio_of_sums,
       count() AS trips
FROM taxi.fact_trips
WHERE status = 'completed'
GROUP BY city, car_class
ORDER BY city, car_class;
