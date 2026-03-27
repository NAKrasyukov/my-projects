USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'ADM_DBFileResizeLog', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'Задание для записи информации из ринг буффера Extended Event [Track_File_Autogrow] в таблицу.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'TECHNODOM\iknae', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'ADM_DBFileResizeLog', @server_name = @@SERVERNAME
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'ADM_DBFileResizeLog', @step_name=N'1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON;
		INSERT INTO dbo.FileAutoGrowLog
(
    EventTime, EventName, DatabaseName, FileName, FileType,
    SizeChangeKB, TotalSizeKB, DurationMs, SessionId,
    SqlText, LoginName, ApplicationName
)
SELECT
    
    CAST(
        SWITCHOFFSET(
            (n.value(''@timestamp'',''datetime2'') AT TIME ZONE ''UTC''),
            DATEPART(TZOFFSET, SYSDATETIMEOFFSET())
        ) AS datetime2
    ) AS EventTime,
    n.value(''@name'', ''nvarchar(200)'') AS EventName,
    COALESCE(
        NULLIF(n.value(''(data[@name="database_name"]/value)[1]'', ''nvarchar(200)''),''''),
        DB_NAME(n.value(''(data[@name="database_id"]/value)[1]'', ''int''))
    ) AS DatabaseName,
    n.value(''(data[@name="file_name"]/value)[1]'', ''nvarchar(200)'') AS FileName,
    n.value(''(data[@name="file_type"]/text)[1]'', ''nvarchar(50)'') AS FileType,
    n.value(''(data[@name="size_change_kb"]/value)[1]'', ''bigint'') AS SizeChangeKB,
    n.value(''(data[@name="total_size_kb"]/value)[1]'', ''bigint'') AS TotalSizeKB,
    n.value(''(data[@name="duration"]/value)[1]'', ''bigint'') AS DurationMs,
    n.value(''(action[@name="session_id"]/value)[1]'', ''int'') AS SessionId,
    n.value(''(action[@name="sql_text"]/value)[1]'', ''nvarchar(max)'') AS SqlText,
    n.value(''(action[@name="server_principal_name"]/value)[1]'', ''nvarchar(200)'') AS LoginName,
    n.value(''(action[@name="client_app_name"]/value)[1]'', ''nvarchar(200)'') AS ApplicationName
FROM (
    SELECT CAST(t.target_data AS XML) AS TargetData
    FROM sys.dm_xe_session_targets t
    JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
    WHERE s.name = ''Track_File_Autogrow''
      AND t.target_name = ''ring_buffer''
) x
CROSS APPLY TargetData.nodes(''//RingBufferTarget/event'') AS q(n);
', 
		@database_name=N'msdb', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'ADM_DBFileResizeLog', @step_name=N'2', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Очистка ring_buffer

ALTER EVENT SESSION [Track_File_Autogrow] ON SERVER STATE = STOP;
GO
ALTER EVENT SESSION [Track_File_Autogrow] ON SERVER STATE = START;
GO
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'ADM_DBFileResizeLog', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'Задание для записи информации из ринг буффера Extended Event [Track_File_Autogrow] в таблицу.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'ADM_DBFileResizeLog', @name=N'1', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20260106, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
