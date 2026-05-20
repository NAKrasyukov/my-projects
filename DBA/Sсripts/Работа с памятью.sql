SELECT sql_memory_model_desc
FROM sys.dm_os_sys_info;

SELECT *
FROM sys.dm_os_process_memory;


SELECT
    physical_memory_in_use_kb / 1024 AS physical_memory_mb,
    locked_page_allocations_kb / 1024 AS locked_pages_mb,
    virtual_address_space_committed_kb / 1024 AS committed_mb,
    process_physical_memory_low,
    process_virtual_memory_low
FROM sys.dm_os_process_memory;


SELECT TOP 20
    type,
    pages_kb / 1024 AS mb
FROM sys.dm_os_memory_clerks
ORDER BY pages_kb DESC;

SELECT
    tl.request_session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    COUNT(*) AS lock_count
FROM sys.dm_tran_locks tl
JOIN sys.dm_exec_sessions s
    ON tl.request_session_id = s.session_id
GROUP BY
    tl.request_session_id,
    s.login_name,
    s.host_name,
    s.program_name
ORDER BY lock_count DESC;


SELECT
    name,
    lock_escalation_desc
FROM sys.tables
WHERE lock_escalation_desc <> 'TABLE';


SELECT
    request_session_id,
    resource_type,
    request_mode,
    COUNT(*) AS cnt
FROM sys.dm_tran_locks
GROUP BY
    request_session_id,
    resource_type,
    request_mode
ORDER BY cnt DESC;

DBCC OPENTRAN;