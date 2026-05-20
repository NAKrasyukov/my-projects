
SELECT TOP 20
    type,
    pages_kb / 1024 AS mb
FROM sys.dm_os_memory_clerks
ORDER BY pages_kb DESC;

SELECT
    session_id,
    requested_memory_kb,
    granted_memory_kb,
    required_memory_kb,
    ideal_memory_kb,
    wait_time_ms,
    queue_id,
    dop,
    timeout_sec,
    text.text
FROM sys.dm_exec_query_memory_grants mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) text
ORDER BY requested_memory_kb DESC;