/*
	If the repository database exists, create a user associated with the service account (if required) and make it db_owner
	Otherwise allow the service account permissions to create the database.  Revoke this permission if the database exists as it's no longer required.
*/

DECLARE @LoginName SYSNAME = 'TECHNODOM\DBAdashService' -- ”казать учетку под которой запущен сервис
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

IF DB_ID('DBADashDB') IS NOT NULL
BEGIN
	SET @SQL = N'USE [DBADashDB]
DECLARE @SQL NVARCHAR(MAX)
DECLARE @UserName SYSNAME
/* Find the user mapped to the login */
SET @UserName = NULL
SELECT @UserName = name
FROM sys.database_principals
WHERE sid= SUSER_SID(@LoginName)

/* Create a user for the login if required */
IF @UserName IS NULL
BEGIN
	SET @SQL = N''CREATE USER '' + QUOTENAME(@LoginName) + '' FOR LOGIN '' + QUOTENAME(@LoginName)
	PRINT @SQL
	EXEC sp_executesql @SQL
	SET @UserName = @LoginName
END

DECLARE @OwnerSQL NVARCHAR(MAX)
SET @OwnerSQL = N''ALTER ROLE db_owner ADD MEMBER '' + QUOTENAME(@UserName)
IF @UserName <> ''dbo'' COLLATE DATABASE_DEFAULT
BEGIN
	PRINT @OwnerSQL
	EXEC sp_executesql @OwnerSQL
END

USE [master]
SET @SQL = ''REVOKE CREATE ANY DATABASE TO '' + QUOTENAME(@LoginName)
PRINT @SQL
EXEC sp_executesql @SQL
'
	EXEC sp_executesql @SQL,N'@LoginName SYSNAME',@LoginName
END
ELSE
BEGIN
	USE [master]
	SET @SQL = 'GRANT CREATE ANY DATABASE TO ' + QUOTENAME(@LoginName)
	PRINT @SQL
	EXEC sp_executesql @SQL
END
