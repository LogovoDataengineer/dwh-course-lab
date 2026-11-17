-- Урок 13: недельные когорты пассажиров — доля когорты, совершившая поездку через N недель после первой.
-- Пусто (NULL) — эта неделя ещё не наступила, а не «никто не вернулся».
WITH rides AS (
    SELECT rider_id, toMonday(trip_date) AS week
    FROM taxi.fact_trips WHERE status = 'completed'
    GROUP BY rider_id, week
), cohorts AS (
    SELECT rider_id, week, min(week) OVER (PARTITION BY rider_id) AS cohort_week FROM rides
)
SELECT cohort_week,
       uniqExactIf(rider_id, week = cohort_week) AS riders,
       if(cohort_week + 7 <= last_week, round(100 * uniqExactIf(rider_id, dateDiff('week', cohort_week, week) = 1) / riders), NULL) AS w1_pct,
       if(cohort_week + 14 <= last_week, round(100 * uniqExactIf(rider_id, dateDiff('week', cohort_week, week) = 2) / riders), NULL) AS w2_pct,
       if(cohort_week + 28 <= last_week, round(100 * uniqExactIf(rider_id, dateDiff('week', cohort_week, week) = 4) / riders), NULL) AS w4_pct,
       if(cohort_week + 56 <= last_week, round(100 * uniqExactIf(rider_id, dateDiff('week', cohort_week, week) = 8) / riders), NULL) AS w8_pct
FROM cohorts, (SELECT max(toMonday(trip_date)) AS last_week FROM taxi.fact_trips) lw
WHERE cohort_week >= '2026-01-12'   -- первую неделю пропускаем: в ней «новые» — все, кто ездил и раньше
GROUP BY cohort_week, last_week
ORDER BY cohort_week;
