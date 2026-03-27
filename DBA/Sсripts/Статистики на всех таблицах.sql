SELECT 
    s.name AS StatName,
    OBJECT_NAME(s.object_id) AS TableName,
    sp.last_updated,
    sp.modification_counter,
    sp.rows,
    -- Показывает % изменений (примерный)
    (CAST(sp.modification_counter AS FLOAT) / NULLIF(sp.rows, 0)) * 100 AS PercentChanged
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE sp.modification_counter > 0 
order by sp.last_updated desc