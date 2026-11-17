-- Урок 12: загрузка сателлита лояльности (решение задачи урока 11), чтобы у PIT было два сателлита.
CREATE TABLE IF NOT EXISTS dv.sat_customer_loyalty (
    hk_customer char(32) NOT NULL, load_dts timestamp NOT NULL, hashdiff char(32) NOT NULL,
    tier text, points integer, record_source text NOT NULL, PRIMARY KEY (hk_customer, load_dts));
INSERT INTO dv.sat_customer_loyalty (hk_customer, load_dts, hashdiff, tier, points, record_source)
SELECT s.hk, :'load_dts', s.hashdiff, s.tier, s.points, 'crm'
FROM (SELECT md5(ltrim(trim(client_ref), '0')) AS hk, md5(concat_ws('|', tier, points)) AS hashdiff, tier, points
      FROM stage_dv.loyalty_cards) s
LEFT JOIN (SELECT DISTINCT ON (hk_customer) hk_customer, hashdiff FROM dv.sat_customer_loyalty
           ORDER BY hk_customer, load_dts DESC) last ON last.hk_customer = s.hk
WHERE last.hashdiff IS DISTINCT FROM s.hashdiff;
