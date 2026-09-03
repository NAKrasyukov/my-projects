
DECLARE @SQL NVARCHAR(MAX) = N'';

SELECT @SQL = @SQL+N'
DECLARE 
    @FileName sysname,
    @TargetSize INT,
    @Factor FLOAT = .99,
    @MinSize INT;
DECLARE @msg VARCHAR(200);
'

SELECT @SQL = @SQL + N'
USE ' + QUOTENAME(name) + N';

-- Обрабатываем каждый DATA-файл базы
DECLARE FileCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT 
    name,
    CEILING(FILEPROPERTY(name, ''SpaceUsed'') * 8.0 / 1024.0) + 1
FROM sys.database_files
WHERE type_desc = ''ROWS'';

OPEN FileCursor;

FETCH NEXT FROM FileCursor INTO @FileName, @MinSize;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Определяем текущий размер файла и рассчитываем начальный TargetSize
    SET @TargetSize = (
        SELECT 1 + size * 8.0 / 1024 - 10000
        FROM sys.database_files
        WHERE name = @FileName
    );

    SET @TargetSize *= @Factor;

    SELECT 
        DB_NAME() AS DatabaseName,
        @FileName AS FileName,
        @TargetSize AS InitialTargetSize,
        @MinSize AS MinSize;

    WHILE @TargetSize > @MinSize
    BEGIN
        SET @TargetSize *= @Factor;

        DBCC SHRINKFILE(@FileName, @TargetSize);

        SET @msg  = CONCAT(''Shrink file completed. Target Size: '', 
             @TargetSize, '' MB. Timestamp: '', CURRENT_TIMESTAMP);
        RAISERROR(@msg, 1, 1) WITH NOWAIT;

        WAITFOR DELAY ''00:00:01'';
    END;

    FETCH NEXT FROM FileCursor INTO @FileName, @MinSize;
END;

CLOSE FileCursor;
DEALLOCATE FileCursor;
'
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE';

  select @SQL
EXEC sys.sp_executesql @SQL;