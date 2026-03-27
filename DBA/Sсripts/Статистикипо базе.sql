SELECT
    s.name AS statistics_name,
    t.name AS table_name,
    sp.last_updated,
    sp.rows,
    sp.rows_sampled,
    sp.modification_counter -- Количество изменений с момента обновления
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
JOIN sys.tables t ON s.object_id = t.object_id
ORDER BY sp.modification_counter DESC; -- Сначала самые устаревшие