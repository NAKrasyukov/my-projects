    -- kill 66 DBCC TRACESTATUS(-1); select count(*) from #tt33
    SELECT
    r.session_id                                   AS spid,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(r.database_id)                         AS database_name,
    
    r.status,
    r.command,

    -- время старта запроса  sp_Who2  SP_SPACEUSED  dbcc opentran()
    r.start_time                                   AS query_start_time,

    -- сколько hh (выполняется:mm:ss)
    CONVERT(varchar(8),
        DATEADD(ms, r.total_elapsed_time, 0), 108
    )                                              AS elapsed_time_hhmmss,

    r.total_elapsed_time                           AS elapsed_time_ms,
    r.percent_complete,
    r.blocking_session_id                          AS blocking_spid,
    -- блокирующий заголовок
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM sys.dm_exec_requests r2
            WHERE r2.blocking_session_id = r.session_id
        )
        THEN 1
        ELSE 0
    END                                            AS is_blocking_header,
    CASE 
        WHEN r.blocking_session_id = 0 THEN NULL
        ELSE 'BLOCKED'
    END                                            AS block_status,
    r.wait_type,
    r.wait_time,
    r.wait_resource,

    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.open_transaction_count,

    -- текст текущего statement
    SUBSTRING(
        t.text,
        (r.statement_start_offset / 2) + 1,
        (
            CASE 
                WHEN r.statement_end_offset = -1 
                THEN LEN(t.text)
                ELSE (r.statement_end_offset - r.statement_start_offset) / 2
            END
        ) + 1
    )                                              AS query_text,

    -- полный batch
    t.text                                         AS batch_text

FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t

WHERE r.session_id <> @@SPID
ORDER BY
    is_blocking_header DESC,
    r.blocking_session_id DESC,
    r.total_elapsed_time DESC;

    --kill 94   
   -- DBCC UPDATEUSAGE (TDJournal, Data)


   -- sp_who2
   /*

  SELECT 
    at.transaction_id,
    at.name,
    at.transaction_begin_time,
    at.transaction_state,
    st.session_id,
    s.login_name,
    s.host_name,
    s.program_name
FROM sys.dm_tran_active_transactions at
JOIN sys.dm_tran_session_transactions st 
    ON at.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s 
    ON st.session_id = s.session_id;


   SELECT TOP 20
    qs.total_logical_reads,
    qs.total_logical_writes,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_reads,
    SUBSTRING(qt.text, 1, 1000) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_logical_reads DESC;

SELECT TOP 10 *
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;


SELECT 
    DB_NAME(database_id) AS db_name,
    file_id,
    num_of_reads,
    num_of_writes,
    io_stall_read_ms,
    io_stall_write_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL);


SELECT 
    r.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    DB_NAME(r.database_id) AS db_name,
    t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
ORDER BY r.reads DESC;


SELECT TOP 20
    qs.total_logical_reads,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_reads,
    SUBSTRING(qt.text, 1, 1000) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_logical_reads DESC;


SELECT 
    SUM(user_object_reserved_page_count) * 8 AS KB,
    SUM(internal_object_reserved_page_count) * 8 AS KB_internal
FROM sys.dm_db_file_space_usage;

SELECT 
    cntr_value AS PageLifeExpectancy
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Page life expectancy';

--ss

SELECT TOP 10
    qs.execution_count,
    qs.total_logical_reads,
    qs.last_logical_reads,
    qs.max_logical_reads,
    qs.last_execution_time,
    SUBSTRING(qt.text, 1, 1000) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.last_logical_reads DESC;

*/