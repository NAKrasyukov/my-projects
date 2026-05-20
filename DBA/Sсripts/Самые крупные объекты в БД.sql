SELECT 
    t.name AS TableName,
    i.name as indexName,
    sum(p.rows) as RowCounts,
    sum(a.total_pages) as TotalPages, 
    sum(a.used_pages) as UsedPages, 
    sum(a.data_pages) as DataPages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
    (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
    (sum(a.data_pages) * 8) / 1024 as DataSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    t.name NOT LIKE 'dt%' AND
    i.object_id > 255 AND  
    i.index_id <= 1
GROUP BY 
    t.name, i.object_id, i.index_id, i.name 
ORDER BY 
    TotalSpaceMB desc



    --EXEC sp_MSforeachtable 'EXEC sp_spaceused "?"';


    SELECT
    r.session_id,
    r.command,
    r.status,
    r.percent_complete,
    r.start_time,
    r.cpu_time,
    r.total_elapsed_time / 1000 / 60 AS elapsed_minutes,
    r.estimated_completion_time / 1000 / 60 AS eta_minutes,
    DB_NAME(r.database_id) AS database_name,
    t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.command LIKE '%INDEX%';




ALTER INDEX [_AccumRgT22322_1] ON [dbo].[_AccumRgT22322] RESUME;
ALTER INDEX [_AccumRgT22322_1] ON [dbo].[_AccumRgT22322] PAUSE;




SELECT
    OBJECT_NAME(object_id) AS table_name,
    name AS index_name,
    state_desc,
    percent_complete,
    start_time,
    last_pause_time
FROM sys.index_resumable_operations;