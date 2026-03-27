DECLARE @name VARCHAR(100) -- database name
DECLARE @path VARCHAR(256) -- backup filename path
DECLARE @fileName VARCHAR(256) -- filename
DECLARE @fileDate VARCHAR(20) -- used for filename uniqueness
DECLARE @dbList CURSOR

-- Specify the backup location here (e.g., 'D:\SQLBackups\')
SET @path = 'E:\DBBackup\' 

-- Get the current date and time in a specific format for the filename
SELECT @fileDate = CONVERT(VARCHAR(20), GETDATE(), 112) + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '')

-- Define the cursor to select all databases
SET @dbList = CURSOR FOR
SELECT name FROM master.sys.databases 
WHERE name NOT IN ('tempdb') -- tempdb is recreated on server start and cannot be backed up
-- Optionally, you can add 'AND state = 0' to ensure only online databases are selected

OPEN @dbList
FETCH NEXT FROM @dbList INTO @name

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @fileName = @path + @name + '_' + @fileDate + '.BAK'
    -- Build the backup command
    DECLARE @sqlCommand NVARCHAR(MAX)
    SET @sqlCommand = 'BACKUP DATABASE [' + @name + '] TO DISK = N''' + @fileName + ''' WITH NOFORMAT, INIT, NAME = N''' + @name + ' Full Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'
    
    -- Execute the backup command
	PRINT 'Started backup of database ' + @name
    --EXECUTE sp_executesql @sqlCommand
    --select @sqlCommand


    -- Optional: Verify the backup integrity immediately after creation
    -- DECLARE @verifyCommand NVARCHAR(MAX)
    -- SET @verifyCommand = 'RESTORE VERIFYONLY FROM DISK = N''' + @fileName + ''''
    -- EXECUTE sp_executesql @verifyCommand

    FETCH NEXT FROM @dbList INTO @name
END

CLOSE @dbList
DEALLOCATE @dbList

PRINT 'All user and system databases have been backed up to ' + @path


