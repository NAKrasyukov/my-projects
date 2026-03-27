USE [master]
GO
-- Drop login if EXISTS AuditUser
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'AuditUser')
BEGIN
    DROP LOGIN [AuditUser];
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