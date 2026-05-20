WITH IndexSizes AS
(
    SELECT
        i.object_id,
        i.index_id,
        OBJECT_NAME(i.object_id) AS table_name,
        i.name AS index_name,
        i.type_desc,
        i.fill_factor,

        SUM(a.total_pages) * 8.0 / 1024 AS total_mb,
        SUM(a.used_pages) * 8.0 / 1024 AS used_mb,
        SUM(a.data_pages) * 8.0 / 1024 AS data_mb

    FROM sys.indexes i
    JOIN sys.partitions p
        ON i.object_id = p.object_id
        AND i.index_id = p.index_id
    JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
    WHERE i.index_id > 0
    GROUP BY
        i.object_id,
        i.index_id,
        i.name,
        i.type_desc,
        i.fill_factor
)

SELECT
    s.table_name,
    s.index_name,
    s.type_desc,
    CAST(s.total_mb AS DECIMAL(18,2)) AS total_mb,
    CAST(s.used_mb AS DECIMAL(18,2)) AS used_mb,
    CAST(s.data_mb AS DECIMAL(18,2)) AS data_mb,

    us.user_seeks,
    us.user_scans,
    us.user_lookups,
    us.user_updates,

    us.last_user_seek,
    us.last_user_scan,
    us.last_user_lookup,
    us.last_user_update

FROM IndexSizes s
LEFT JOIN sys.dm_db_index_usage_stats us
    ON s.object_id = us.object_id
    AND s.index_id = us.index_id
    AND us.database_id = DB_ID()

ORDER BY s.total_mb DESC;







SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,

    ips.page_count * 8 / 1024 AS size_mb,
    ips.avg_fragmentation_in_percent,
    ips.avg_page_space_used_in_percent,

    us.user_seeks,
    us.user_scans,
    us.user_lookups,
    us.user_updates

FROM sys.indexes i

JOIN sys.dm_db_index_physical_stats
(
    DB_ID(),
    NULL,
    NULL,
    NULL,
    'LIMITED'
) ips
    ON i.object_id = ips.object_id
    AND i.index_id = ips.index_id

LEFT JOIN sys.dm_db_index_usage_stats us
    ON i.object_id = us.object_id
    AND i.index_id = us.index_id
    AND us.database_id = DB_ID()

WHERE i.index_id > 0
AND ips.page_count > 1000

ORDER BY size_mb DESC;