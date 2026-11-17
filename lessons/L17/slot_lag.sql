-- Урок 17: сколько журнала WAL удерживает слот Debezium — отставание от текущей позиции журнала.
SELECT slot_name, active, confirmed_flush_lsn,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS lag
FROM pg_replication_slots WHERE slot_name = 'dwh_cdc';
