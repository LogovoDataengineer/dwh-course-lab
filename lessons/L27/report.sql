-- Урок 27: отчёт монитора качества — какие дни не прошли какие проверки.
SELECT check_date, check_name, value
FROM dq.daily_checks
WHERE failed
ORDER BY check_date, check_name;
SELECT count(*) AS checks, count(*) FILTER (WHERE failed) AS failed FROM dq.daily_checks;
