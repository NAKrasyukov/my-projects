
--Общая информация об индексах на таблице
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.fill_factor,
    SUM(a.total_pages) * 8 / 1024 AS total_mb,
    SUM(a.used_pages) * 8 / 1024 AS used_mb,
    SUM(a.data_pages) * 8 / 1024 AS data_mb
FROM sys.indexes i
JOIN sys.partitions p
    ON i.object_id = p.object_id
    AND i.index_id = p.index_id
JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
WHERE i.object_id = OBJECT_ID('dbo._AccumRgT22322') --указать таблицу
GROUP BY
    i.object_id,
    i.name,
    i.type_desc,
    i.fill_factor
ORDER BY total_mb DESC;

-- fill_factor
SELECT
    name,
    fill_factor
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo._AccumRgT22322'); --указать таблицу

-- Использовавние индекса
SELECT
    i.name,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i
    ON s.object_id = i.object_id
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
AND i.object_id = OBJECT_ID('dbo._AccumRgT22322'); --указать таблицу

-- is_included_column
SELECT
    i.name,
    c.name,
    ic.is_included_column
FROM sys.indexes i
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
JOIN sys.columns c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo._AccumRgT22322') --указать таблицу
ORDER BY i.name, ic.key_ordinal;