DECLARE @LoginName SYSNAME = 'TECHNODOM\DBAdashService' -- ”казать учетку под которой запущен сервис
DECLARE @UserName SYSNAME
DECLARE @SQL NVARCHAR(MAX)

/* For case sensitive collations, we want the @LoginName case to match what is in sys.server_principals if the login exists. */
SELECT @LoginName = name
FROM sys.server_principals
WHERE name = @LoginName COLLATE SQL_Latin1_General_CP1_CI_AS

/* Create the login if it doesn't exist */
IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = @LoginName)
BEGIN
	SET @SQL = N'CREATE LOGIN ' + QUOTENAME(@LoginName) + ' FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
	PRINT @SQL
	EXEC sp_executesql @SQL
END


/* Find the user mapped to the login */
SET @UserName = NULL
SELECT @UserName = name
FROM sys.database_principals
WHERE sid= SUSER_SID(@LoginName)

/* Create a user for the login if required */
IF @UserName IS NULL
BEGIN
	SET @SQL = N'CREATE USER ' + QUOTENAME(@LoginName) + ' FOR LOGIN ' + QUOTENAME(@LoginName)
	PRINT @SQL
	EXEC sp_executesql @SQL
	SET @UserName = @LoginName
END

/* GRANT EXECUTE */ 
IF OBJECT_ID('DBADash_CustomCheck') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [DBADash_CustomCheck] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('DBADash_CustomPerformanceCounters') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [DBADash_CustomPerformanceCounters] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzBackups') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzBackups] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzCache') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzCache] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzFirst') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzFirst] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzIndex') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzIndex] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzLock') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzLock] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzWho') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzWho] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_DBPermissions') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_DBPermissions] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HealthParser') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HealthParser] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HumanEvents') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HumanEvents] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HumanEventsBlockViewer') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HumanEventsBlockViewer] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_IndexCleanup') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_IndexCleanup] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_PressureDetector') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_PressureDetector] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_QuickieStore') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_QuickieStore] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_SrvPermissions') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_SrvPermissions] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_WhoIsActive') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_WhoIsActive] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

/* Add Database Roles */ 
USE [msdb]
/* Find the user mapped to the login */
SET @UserName = NULL
SELECT @UserName = name
FROM sys.database_principals
WHERE sid= SUSER_SID(@LoginName)

/* Create a user for the login if required */
IF @UserName IS NULL
BEGIN
	SET @SQL = N'CREATE USER ' + QUOTENAME(@LoginName) + ' FOR LOGIN ' + QUOTENAME(@LoginName)
	PRINT @SQL
	EXEC sp_executesql @SQL
	SET @UserName = @LoginName
END

SET @SQL = N'ALTER ROLE [db_datareader] ADD MEMBER ' + QUOTENAME(@UserName)
PRINT @SQL
EXEC sp_executesql @SQL
SET @SQL = N'ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER ' + QUOTENAME(@UserName)
PRINT @SQL
EXEC sp_executesql @SQL
/* SERVER LEVEL GRANTS */ 
USE [master]
/* Find the user mapped to the login */
SET @UserName = NULL
SELECT @UserName = name
FROM sys.database_principals
WHERE sid= SUSER_SID(@LoginName)

/* Create a user for the login if required */
IF @UserName IS NULL
BEGIN
	SET @SQL = N'CREATE USER ' + QUOTENAME(@LoginName) + ' FOR LOGIN ' + QUOTENAME(@LoginName)
	PRINT @SQL
	EXEC sp_executesql @SQL
	SET @UserName = @LoginName
END

SET @SQL = N'GRANT ALTER ANY EVENT SESSION TO ' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL
SET @SQL = N'GRANT CONNECT ANY DATABASE TO ' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL
SET @SQL = N'GRANT VIEW ANY DATABASE TO ' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL
SET @SQL = N'GRANT VIEW ANY DEFINITION TO ' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL
SET @SQL = N'GRANT VIEW SERVER STATE TO ' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL

/* GRANT EXECUTE in master */
IF OBJECT_ID('sp_BlitzBackups') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzBackups] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzCache') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzCache] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzFirst') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzFirst] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzIndex') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzIndex] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzLock') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzLock] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_BlitzWho') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_BlitzWho] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_DBPermissions') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_DBPermissions] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HealthParser') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HealthParser] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HumanEvents') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HumanEvents] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_HumanEventsBlockViewer') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_HumanEventsBlockViewer] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_IndexCleanup') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_IndexCleanup] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_PressureDetector') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_PressureDetector] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_QuickieStore') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_QuickieStore] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_SrvPermissions') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_SrvPermissions] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END

IF OBJECT_ID('sp_WhoIsActive') IS NOT NULL
BEGIN
	SET @SQL = N'GRANT EXECUTE ON [sp_WhoIsActive] TO ' + QUOTENAME(@UserName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END