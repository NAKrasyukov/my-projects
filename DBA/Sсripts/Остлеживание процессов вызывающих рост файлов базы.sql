-- Создание Extended Event для отслеживания события изменения размера файла базы данных
CREATE EVENT SESSION [Track_File_Autogrow]
ON SERVER
ADD EVENT sqlserver.database_file_size_change(
    ACTION(
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.server_principal_name,
        sqlserver.client_app_name
    )
)
ADD TARGET package0.ring_buffer (SET max_memory = 10240)
WITH (STARTUP_STATE = ON);
GO

ALTER EVENT SESSION [Track_File_Autogrow] ON SERVER STATE = START;
GO

-- Просмотр текущего сожержимого ring_buffer
WITH XEvents AS
(
    SELECT CAST(t.target_data AS XML) AS TargetData
    FROM sys.dm_xe_session_targets t
    JOIN sys.dm_xe_sessions s 
      ON t.event_session_address = s.address
    WHERE s.name = 'Track_File_Autogrow'
      AND t.target_name = 'ring_buffer'
)
SELECT
    n.value('@name', 'nvarchar(200)') AS EventName,
    CAST(
        SWITCHOFFSET(
            (n.value('@timestamp','datetime2') AT TIME ZONE 'UTC'),
            DATEPART(TZOFFSET, SYSDATETIMEOFFSET())
        ) AS datetime2
    ) AS EventTime,
    COALESCE(
        NULLIF(n.value('(data[@name="database_name"]/value)[1]', 'nvarchar(200)'),''),
        DB_NAME(n.value('(data[@name="database_id"]/value)[1]', 'int'))
    ) AS DatabaseName,
    n.value('(data[@name="file_name"]/value)[1]', 'nvarchar(200)') AS FileName,
    n.value('(data[@name="file_type"]/text)[1]', 'nvarchar(50)') AS FileType,
    n.value('(data[@name="size_change_kb"]/value)[1]', 'bigint') AS SizeChangeKB,
    n.value('(data[@name="total_size_kb"]/value)[1]', 'bigint') AS TotalSizeKB,
    n.value('(data[@name="duration"]/value)[1]', 'bigint') AS DurationMs,
    n.value('(action[@name="session_id"]/value)[1]', 'int') AS SessionId,
    n.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS SqlText,
    n.value('(action[@name="server_principal_name"]/value)[1]', 'nvarchar(200)') AS LoginName,
    n.value('(action[@name="client_app_name"]/value)[1]', 'nvarchar(200)') AS ApplicationName
FROM XEvents
CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS q(n);

-- Создание таблицы для хранения исторических данных

CREATE TABLE dbo.FileAutoGrowLog (
    Id INT IDENTITY PRIMARY KEY,
    EventTime DATETIME2,
    EventName NVARCHAR(200),
    DatabaseName NVARCHAR(200),
    FileName NVARCHAR(200),
    FileType NVARCHAR(50),
    SizeChangeKB BIGINT,
    TotalSizeKB BIGINT,
    DurationMs BIGINT,
    SessionId INT,
    SqlText NVARCHAR(MAX),
    LoginName NVARCHAR(200),
    ApplicationName NVARCHAR(200)
);

-- ЗАполнение таблицы из ring_buffer
INSERT INTO dbo.FileAutoGrowLog
(
    EventTime, EventName, DatabaseName, FileName, FileType,
    SizeChangeKB, TotalSizeKB, DurationMs, SessionId,
    SqlText, LoginName, ApplicationName
)
SELECT
    
    CAST(
        SWITCHOFFSET(
            (n.value('@timestamp','datetime2') AT TIME ZONE 'UTC'),
            DATEPART(TZOFFSET, SYSDATETIMEOFFSET())
        ) AS datetime2
    ) AS EventTime,
    n.value('@name', 'nvarchar(200)') AS EventName,
    COALESCE(
        NULLIF(n.value('(data[@name="database_name"]/value)[1]', 'nvarchar(200)'),''),
        DB_NAME(n.value('(data[@name="database_id"]/value)[1]', 'int'))
    ) AS DatabaseName,
    n.value('(data[@name="file_name"]/value)[1]', 'nvarchar(200)') AS FileName,
    n.value('(data[@name="file_type"]/text)[1]', 'nvarchar(50)') AS FileType,
    n.value('(data[@name="size_change_kb"]/value)[1]', 'bigint') AS SizeChangeKB,
    n.value('(data[@name="total_size_kb"]/value)[1]', 'bigint') AS TotalSizeKB,
    n.value('(data[@name="duration"]/value)[1]', 'bigint') AS DurationMs,
    n.value('(action[@name="session_id"]/value)[1]', 'int') AS SessionId,
    n.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS SqlText,
    n.value('(action[@name="server_principal_name"]/value)[1]', 'nvarchar(200)') AS LoginName,
    n.value('(action[@name="client_app_name"]/value)[1]', 'nvarchar(200)') AS ApplicationName
FROM (
    SELECT CAST(t.target_data AS XML) AS TargetData
    FROM sys.dm_xe_session_targets t
    JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
    WHERE s.name = 'Track_File_Autogrow'
      AND t.target_name = 'ring_buffer'
) x
CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS q(n);


-- Очистка ring_buffer

ALTER EVENT SESSION [Track_File_Autogrow] ON SERVER STATE = STOP;
GO
ALTER EVENT SESSION [Track_File_Autogrow] ON SERVER STATE = START;
GO
