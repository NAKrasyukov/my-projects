----------------------- —оздание переменных -----------------------------------------------------------------

DECLARE @BatchSize       INT = 100000;   -- 1000Ц100000 оптимально
DECLARE @DelaySeconds   INT = 20;     -- 30Ц60 сек
DECLARE @RowsDeleted    INT;
DECLARE @CutoffDate     DATETIME = '4025-01-01'; 
DECLARE @Delay CHAR(8) = '00:00:' + RIGHT('00' + CAST(@DelaySeconds AS VARCHAR(2)), 2);

------------------------   ”данление данных из [TDJournal].[dbo].[Data] --------------------------------------


PRINT '=== START DATA CLEANUP ===';

WHILE 1 = 1
BEGIN
    DELETE TOP (@BatchSize) D
    FROM [TDJournal].[dbo].[Data] D
    INNER JOIN [TDJournal].[dbo].[register] R
        ON R.DataHash = D.[hash]
    WHERE R.VersionDate < @CutoffDate;

    SET @RowsDeleted = @@ROWCOUNT;

    PRINT CONCAT('Deleted rows from [Data]: ', @RowsDeleted);

    IF @RowsDeleted = 0
        BREAK;

    WAITFOR DELAY @Delay;
END

PRINT '=== DATA CLEANUP FINISHED ===';


------------------------ «ачистка [TDJournal].[dbo].[register] ------------------------------------

PRINT '=== START REGISTER CLEANUP ===';

WHILE 1 = 1
BEGIN
    DELETE TOP (@BatchSize)
    FROM [TDJournal].[dbo].[register]
    WHERE VersionDate < @CutoffDate;

    SET @RowsDeleted = @@ROWCOUNT;

    PRINT CONCAT('Deleted rows from [register]: ', @RowsDeleted);

    IF @RowsDeleted = 0
        BREAK;

    WAITFOR DELAY @Delay;
END

PRINT '=== REGISTER CLEANUP FINISHED ===';