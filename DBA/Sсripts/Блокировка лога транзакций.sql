select log_reuse_wait_desc,* from sys.databases

DBCC OPENTRAN('ope_008'); -- kill 91

SELECT
    at.transaction_id,
    at.name,
    at.transaction_begin_time,
    DATEDIFF(MINUTE, at.transaction_begin_time, GETDATE()) AS minutes_running,
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    dt.database_id,
    DB_NAME(dt.database_id) AS database_name
FROM sys.dm_tran_active_transactions at
JOIN sys.dm_tran_session_transactions st
    ON at.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s
    ON st.session_id = s.session_id
JOIN sys.dm_tran_database_transactions dt
    ON at.transaction_id = dt.transaction_id
WHERE dt.database_id = DB_ID('ope_118')
ORDER BY at.transaction_begin_time;


SELECT local_net_address, local_tcp_port
FROM sys.dm_exec_connections
WHERE local_tcp_port = 5022;

SELECT 
    d.name,
    drs.database_state_desc,
    drs.synchronization_state_desc,
    drs.is_suspended
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.databases d 
    ON d.database_id = drs.database_id
WHERE d.name = 'ope_025';

ALTER DATABASE ope_025 SET HADR OFF;

SELECT @@VERSION;


SELECT
    database_transaction_begin_time,
    database_transaction_state,
    database_transaction_log_record_count,
    database_transaction_log_bytes_used
FROM sys.dm_tran_database_transactions
WHERE database_id = DB_ID('ope_044');

SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    t.transaction_id,
    t.transaction_begin_time,
    DATEDIFF(minute, t.transaction_begin_time, GETDATE()) AS duration_min,
    r.status,
    r.command
FROM sys.dm_tran_active_transactions t
JOIN sys.dm_tran_session_transactions st
    ON t.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s
    ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
WHERE s.database_id = DB_ID();


EXECUTE [dbo].[DatabaseBackup]
@Databases = 'ope_061',
@Directory = N'D:\DBBackup', 
@BackupType = 'LOG',
@Verify = 'N',
@CleanupTime = 48,
@CheckSum = 'N',
@LogToTable = 'N'

WAITFOR TIME '00:00:20'

USE [ope_061]
GO
DBCC SHRINKFILE (N'ope_099_log' , 0)
GO
