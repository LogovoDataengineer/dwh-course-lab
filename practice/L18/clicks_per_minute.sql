-- Урок 18, шаг 6 (ваш): поминутные окна кликов — представление stream.clicks_per_minute.
-- Столбцы, порядок важен: window_start, clicks, users
--   window_start — начало минутного окна (tumbling) по ВРЕМЕНИ СОБЫТИЯ event_time, а не по времени прихода в Kafka;
--   clicks — число кликов в окне, users — число разных пользователей.
-- В stream.clicks после перечитывания топика каждое событие лежит дважды (at-least-once), поэтому клики
-- считайте по уникальному event_id, а не числом строк.
-- Выполнить: make ch F=practice/L18/clicks_per_minute.sql     Проверить: make check-18
CREATE OR REPLACE VIEW stream.clicks_per_minute AS
SELECT ...
