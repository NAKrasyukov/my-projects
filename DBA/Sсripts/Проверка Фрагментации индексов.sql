
SELECT 
    OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
    OBJECT_NAME(ips.object_id)        AS table_name,
    i.name                            AS index_name,
    i.type_desc                       AS index_type,
    ips.index_id,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats
(
    DB_ID(),        -- текущая БД
    NULL,           -- все таблицы
    NULL,           -- все индексы
    NULL,
    'LIMITED'       -- режим анализа
) ips
JOIN sys.indexes i
    ON ips.object_id = i.object_id
   AND ips.index_id  = i.index_id
WHERE
    ips.index_id > 0        -- исключить heap
    AND ips.page_count > 1000 --and ips.page_count < 1000
    --AND OBJECT_NAME(ips.object_id) = '_AccumRgT22322'
    --and i.name = '_InfoRg39244_3'
ORDER BY
    ips.avg_fragmentation_in_percent DESC;-- page_count avg_fragmentation_in_percent


--    SELECT cpu_count, hyperthread_ratio, numa_node_count FROM sys.dm_os_sys_info

SELECT
    OBJECT_NAME(object_id) AS table_name,
    index_id,
    avg_fragmentation_in_percent,
    avg_page_space_used_in_percent,
    fragment_count,
    page_count
FROM sys.dm_db_index_physical_stats
(
    DB_ID(),
    OBJECT_ID('dbo._AccumRgT22322'),
    NULL,
    NULL,
    'DETAILED'
);

SELECT
    OBJECT_NAME(object_id) AS table_name,
    leaf_allocation_count,
    nonleaf_allocation_count,
    leaf_page_merge_count
FROM sys.dm_db_index_operational_stats
(
    DB_ID(),
    OBJECT_ID('dbo._AccumRgT39253'),
    NULL,
    NULL
);