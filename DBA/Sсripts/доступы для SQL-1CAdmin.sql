-- Create and add access for TECHNODOM\SQL-1CAdmin

USE [master]
GO
-- Drop login if EXISTS TECHNODOM\SQL-1CAdmin
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHNODOM\SQL-1CAdmin')
BEGIN
    DECLARE @login SYSNAME = 'TECHNODOM\SQL-1CAdmin';
    DECLARE @sql NVARCHAR(MAX) = '';

    SELECT @sql += 
        'ALTER SERVER ROLE [' + r.name + '] DROP MEMBER [' + sp.name + '];
        '
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
    WHERE sp.name = @login;
    
    SELECT @sql += 
        CASE 
            WHEN state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 
                'REVOKE GRANT OPTION FOR ' + permission_name + ' TO [' + @login + '];'
            ELSE 
                'REVOKE ' + permission_name + ' FROM [' + @login + '];
                '
        END
    FROM sys.server_permissions
    WHERE grantee_principal_id = SUSER_ID(@login);

    EXEC sp_executesql @sql;

    set @sql = '
    USE [?];
        -- Drop user if EXISTS AuditUser
        DECLARE @user SYSNAME = ''' + @login + ''';
        IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user)
        BEGIN
            DECLARE @cmd NVARCHAR(MAX) = '''';

            SELECT @cmd += 
                ''ALTER ROLE ['' + r.name + ''] DROP MEMBER ['' + u.name + ''];''
            FROM sys.database_role_members rm
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
            WHERE u.name = @user;

            EXEC sp_executesql @cmd;

            -- Удаление прав
            SELECT @cmd = '''';

            SELECT @cmd += 
                CASE 
                    WHEN state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN
                        ''REVOKE GRANT OPTION FOR '' + permission_name + '' TO ['' + @user + ''];''
                    ELSE
                        ''REVOKE '' + permission_name + '' FROM ['' + @user + ''];''
                END
            FROM sys.database_permissions
            WHERE grantee_principal_id = USER_ID(@user);

            EXEC sp_executesql @cmd;
        END;
    ';

    EXEC sp_MSforeachdb @sql
END

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'TECHNODOM\SQL-1CAdmin')
BEGIN
    CREATE LOGIN [TECHNODOM\SQL-1CAdmin] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

GO
ALTER SERVER ROLE [dbcreator] ADD MEMBER [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT CONNECT ANY DATABASE TO [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT CONNECT SQL TO [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT CREATE ANY DATABASE TO [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT VIEW ANY DATABASE TO [TECHNODOM\SQL-1CAdmin]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [TECHNODOM\SQL-1CAdmin]
GO
use [msdb]
GRANT EXECUTE ON dbo.sp_delete_database_backuphistory TO [TECHNODOM\SQL-1CAdmin];
GO

EXEC sp_MSforeachdb '
USE [?];
-- Check if the database is a user database and not one of the system dbs
IF DB_NAME() NOT IN (''master'', ''model'')
BEGIN

    -- Check if the user already exists in the current database TECHNODOM\SQL-1CAdmin
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''TECHNODOM\SQL-1CAdmin'')
    BEGIN
        -- Create the user from the existing login
        CREATE USER [TECHNODOM\SQL-1CAdmin] FOR LOGIN [TECHNODOM\SQL-1CAdmin];
        PRINT ''User [TECHNODOM\SQL-1CAdmin] created in database ?'';
    END
    
    -- Check if the user is already a member of the db_owner role TECHNODOM\SQL-1CAdmin
    IF (IS_SRVROLEMEMBER(''sysadmin'', N''TECHNODOM\SQL-1CAdmin'') IS NULL) -- Only add if not sysadmin at server level
    BEGIN
        IF (IS_MEMBER(''db_owner'') <> 1)
        BEGIN
            -- Add the user to the db_owner role
            ALTER ROLE [db_owner] ADD MEMBER [TECHNODOM\SQL-1CAdmin];
            PRINT ''User [TECHNODOM\SQL-1CAdmin] added to db_owner role in database ?'';
        END
    END
END
';
GO
-- Create and add access for TECHNODOM\1c-service

USE [master]
GO
-- Drop login if EXISTS TECHNODOM\1c-service
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHNODOM\1c-service')
BEGIN
    DECLARE @login SYSNAME = 'TECHNODOM\1c-service';
    DECLARE @sql NVARCHAR(MAX) = '';

    SELECT @sql += 
        'ALTER SERVER ROLE [' + r.name + '] DROP MEMBER [' + sp.name + '];
        '
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
    WHERE sp.name = @login;
    
    SELECT @sql += 
        CASE 
            WHEN state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 
                'REVOKE GRANT OPTION FOR ' + permission_name + ' TO [' + @login + '];'
            ELSE 
                'REVOKE ' + permission_name + ' FROM [' + @login + '];
                '
        END
    FROM sys.server_permissions
    WHERE grantee_principal_id = SUSER_ID(@login);

    EXEC sp_executesql @sql;

    set @sql = '
    USE [?];
        -- Drop user if EXISTS AuditUser
        DECLARE @user SYSNAME = ''' + @login + ''';
        IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user)
        BEGIN
            DECLARE @cmd NVARCHAR(MAX) = '''';

            SELECT @cmd += 
                ''ALTER ROLE ['' + r.name + ''] DROP MEMBER ['' + u.name + ''];''
            FROM sys.database_role_members rm
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
            WHERE u.name = @user;

            EXEC sp_executesql @cmd;

            -- Удаление прав
            SELECT @cmd = '''';

            SELECT @cmd += 
                CASE 
                    WHEN state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN
                        ''REVOKE GRANT OPTION FOR '' + permission_name + '' TO ['' + @user + ''];''
                    ELSE
                        ''REVOKE '' + permission_name + '' FROM ['' + @user + ''];''
                END
            FROM sys.database_permissions
            WHERE grantee_principal_id = USER_ID(@user);

            EXEC sp_executesql @cmd;
        END;
    ';

    EXEC sp_MSforeachdb @sql
END

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'TECHNODOM\1c-service')
BEGIN
    CREATE LOGIN [TECHNODOM\1c-service] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

GO
ALTER SERVER ROLE [dbcreator] ADD MEMBER [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT CONNECT ANY DATABASE TO [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT CONNECT SQL TO [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT CREATE ANY DATABASE TO [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT VIEW ANY DATABASE TO [TECHNODOM\1c-service]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [TECHNODOM\1c-service]
GO
use [msdb]
GRANT EXECUTE ON dbo.sp_delete_database_backuphistory TO [TECHNODOM\1c-service];
GO

EXEC sp_MSforeachdb '
USE [?];
-- Check if the database is a user database and not one of the system dbs
IF DB_NAME() NOT IN (''master'', ''model'')
BEGIN

    -- Check if the user already exists in the current database TECHNODOM\1c-service
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''TECHNODOM\1c-service'')
    BEGIN
        -- Create the user from the existing login
        CREATE USER [TECHNODOM\1c-service] FOR LOGIN [TECHNODOM\1c-service];
        PRINT ''User [TECHNODOM\1c-service] created in database ?'';
    END
    
    -- Check if the user is already a member of the db_owner role TECHNODOM\1c-service
    IF (IS_SRVROLEMEMBER(''sysadmin'', N''TECHNODOM\1c-service'') IS NULL) -- Only add if not sysadmin at server level
    BEGIN
        IF (IS_MEMBER(''db_owner'') <> 1)
        BEGIN
            -- Add the user to the db_owner role
            ALTER ROLE [db_owner] ADD MEMBER [TECHNODOM\1c-service];
            PRINT ''User [TECHNODOM\1c-service] added to db_owner role in database ?'';
        END
    END
END
';
GO

-- Create and add access for TECHNODOM\SQL-DEV-TEAM

USE [master]
GO
-- Drop login if EXISTS TECHNODOM\SQL-1CAdmin
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'TECHNODOM\SQL-DEV-TEAM')
BEGIN
    DECLARE @login SYSNAME = 'TECHNODOM\SQL-DEV-TEAM';
    DECLARE @sql NVARCHAR(MAX) = '';

    SELECT @sql += 
        'ALTER SERVER ROLE [' + r.name + '] DROP MEMBER [' + sp.name + '];
        '
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
    WHERE sp.name = @login;
    
    SELECT @sql += 
        CASE 
            WHEN state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 
                'REVOKE GRANT OPTION FOR ' + permission_name + ' TO [' + @login + '];'
            ELSE 
                'REVOKE ' + permission_name + ' FROM [' + @login + '];
                '
        END
    FROM sys.server_permissions
    WHERE grantee_principal_id = SUSER_ID(@login);

    EXEC sp_executesql @sql;

    set @sql = '
    USE [?];
        -- Drop user if EXISTS AuditUser
        DECLARE @user SYSNAME = ''' + @login + ''';
        IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user)
        BEGIN
            DECLARE @cmd NVARCHAR(MAX) = '''';

            SELECT @cmd += 
                ''ALTER ROLE ['' + r.name + ''] DROP MEMBER ['' + u.name + ''];''
            FROM sys.database_role_members rm
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
            WHERE u.name = @user;

            EXEC sp_executesql @cmd;

            -- Удаление прав
            SELECT @cmd = '''';

            SELECT @cmd += 
                CASE 
                    WHEN state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN
                        ''REVOKE GRANT OPTION FOR '' + permission_name + '' TO ['' + @user + ''];''
                    ELSE
                        ''REVOKE '' + permission_name + '' FROM ['' + @user + ''];''
                END
            FROM sys.database_permissions
            WHERE grantee_principal_id = USER_ID(@user);

            EXEC sp_executesql @cmd;
        END;
    ';

    EXEC sp_MSforeachdb @sql
END

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'TECHNODOM\SQL-DEV-TEAM')
BEGIN
    CREATE LOGIN [TECHNODOM\SQL-DEV-TEAM] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

GO
ALTER SERVER ROLE [dbcreator] ADD MEMBER [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT CONNECT ANY DATABASE TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT CONNECT SQL TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT CREATE ANY DATABASE TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT VIEW ANY DATABASE TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [TECHNODOM\SQL-DEV-TEAM]
GO
use [msdb]
GRANT EXECUTE ON dbo.sp_delete_database_backuphistory TO [TECHNODOM\SQL-DEV-TEAM];
GO

EXEC sp_MSforeachdb '
USE [?];
-- Check if the database is a user database and not one of the system dbs
IF DB_NAME() NOT IN (''master'', ''model'')
BEGIN

    -- Check if the user already exists in the current database TECHNODOM\SQL-DEV-TEAM
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''TECHNODOM\SQL-DEV-TEAM'')
    BEGIN
        -- Create the user from the existing login
        CREATE USER [TECHNODOM\SQL-DEV-TEAM] FOR LOGIN [TECHNODOM\SQL-DEV-TEAM];
        PRINT ''User [TECHNODOM\SQL-DEV-TEAM] created in database ?'';
    END
    
    -- Check if the user is already a member of the db_owner role TECHNODOM\SQL-DEV-TEAM
    IF (IS_SRVROLEMEMBER(''sysadmin'', N''TECHNODOM\SQL-DEV-TEAM'') IS NULL) -- Only add if not sysadmin at server level
    BEGIN
        IF (IS_MEMBER(''db_owner'') <> 1)
        BEGIN
            -- Add the user to the db_owner role
            ALTER ROLE [db_owner] ADD MEMBER [TECHNODOM\SQL-DEV-TEAM];
            PRINT ''User [TECHNODOM\SQL-DEV-TEAM] added to db_owner role in database ?'';
        END
    END
END
';
GO

/*
-- AuditUser OSA-1691

USE [master]
GO
-- Drop login if EXISTS AuditUser
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'AuditUser')
BEGIN
    
    DECLARE @login SYSNAME = 'AuditUser';
    DECLARE @sql NVARCHAR(MAX) = '';

    SELECT @sql += 
        'ALTER SERVER ROLE [' + r.name + '] DROP MEMBER [' + sp.name + '];
        '
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals sp ON rm.member_principal_id = sp.principal_id
    WHERE sp.name = @login;
    
    SELECT @sql += 
        CASE 
            WHEN state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 
                'REVOKE GRANT OPTION FOR ' + permission_name + ' TO [' + @login + '];'
            ELSE 
                'REVOKE ' + permission_name + ' FROM [' + @login + '];
                '
        END
    FROM sys.server_permissions
    WHERE grantee_principal_id = SUSER_ID(@login);

    EXEC sp_executesql @sql;

    set @sql = '
    USE [?];
        -- Drop user if EXISTS AuditUser
        DECLARE @user SYSNAME = ''' + @login + ''';
        IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @user)
        BEGIN
            DECLARE @cmd NVARCHAR(MAX) = '''';

            SELECT @cmd += 
                ''ALTER ROLE ['' + r.name + ''] DROP MEMBER ['' + u.name + ''];''
            FROM sys.database_role_members rm
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
            WHERE u.name = @user;

            EXEC sp_executesql @cmd;

            -- Удаление прав
            SELECT @cmd = '''';

            SELECT @cmd += 
                CASE 
                    WHEN state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN
                        ''REVOKE GRANT OPTION FOR '' + permission_name + '' TO ['' + @user + ''];''
                    ELSE
                        ''REVOKE '' + permission_name + '' FROM ['' + @user + ''];''
                END
            FROM sys.database_permissions
            WHERE grantee_principal_id = USER_ID(@user);

            EXEC sp_executesql @cmd;
        END;
    ';

    EXEC sp_MSforeachdb @sql

END


IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'AuditUser')
BEGIN
    CREATE LOGIN [AuditUser] WITH PASSWORD=N'q213946Bm0R2zd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
END

GRANT CONNECT SQL TO [AuditUser]

GRANT VIEW SERVER STATE TO AuditUser;
GRANT VIEW ANY DEFINITION TO AuditUser;

EXEC sp_MSforeachdb '
USE [?];
    -- Drop user if EXISTS AuditUser
    IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N''AuditUser'')
    BEGIN
        DROP USER [AuditUser];
    END

    -- Check if the user already exists in the current database AuditUser
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''AuditUser'')
    BEGIN
        -- Create the user from the existing login
        CREATE USER [AuditUser] FOR LOGIN [AuditUser];
        PRINT ''User [AuditUser] created in database ?'';
    END
    ALTER ROLE db_datareader ADD MEMBER AuditUser;
';
GO