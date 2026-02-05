
    SELECT
    r.session_id                                   AS spid,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(r.database_id)                         AS database_name,
    
    r.status,
    r.command,

    -- время старта запроса
    r.start_time                                   AS query_start_time,

    -- сколько выполняется (hh:mm:ss)
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

    --kill 75