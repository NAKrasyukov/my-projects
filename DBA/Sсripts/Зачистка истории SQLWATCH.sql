
---------------Проверка всей истории ------------------------------
USE msdb;
GO

SELECT 
    j.name,
    COUNT(*) AS cnt
FROM dbo.sysjobhistory h
JOIN dbo.sysjobs j ON h.job_id = j.job_id
GROUP BY j.name
ORDER BY cnt DESC;



Select top(1)run_date from dbo.sysjobhistory
order by run_date 
-------------------------------------------------------------------

---------------Зачистка всей истории старше 3х месяцев-------------

USE msdb;
GO

-- Calculate the date 3 months ago (e.g., 90 days)
DECLARE @cutoffDate DATETIME = DATEADD(MONTH, -3, GETDATE());

-- Purge history for a specific job (optional)
EXEC msdb.dbo.sp_purge_jobhistory 
    @oldest_date = @cutoffDate;

-------------------------------------------------------------------


---------------Зачистка истории SqlWhatch--------------------------

USE msdb;
GO

DECLARE @cutoffDate DATETIME = DATEADD(day, -1, GETDATE());

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-WHOISACTIVE', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-PERFORMANCE', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-ACTIONS', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-XES', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-CHECKS', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-AG', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-AGENT-HISTORY', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-PROCS', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-REPORT-AZMONITOR', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-CONFIG', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-TRENDS', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-TRENDS', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-DISK-UTILISATION', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-INTERNAL-RETENTION', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-INDEXES', 
    @oldest_date = @cutoffDate;

EXEC msdb.dbo.sp_purge_jobhistory 
    @job_name = N'SQLWATCH-LOGGER-SYSCONFIG', 
    @oldest_date = @cutoffDate;

-------------------------------------------------------------------


---------------Оптимизация базы после зачистки---------------------

USE [msdb]
GO
DBCC SHRINKFILE (N'MSDBData' , 0)
GO


USE [msdb]
GO
ALTER INDEX [PK__backupfi__57D1800AFBB26665] ON [dbo].[backupfile] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
USE [msdb]
GO
ALTER INDEX [clust] ON [dbo].[sysjobhistory] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
USE [msdb]
GO
ALTER INDEX [nc1] ON [dbo].[sysjobhistory] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

USE [msdb]
GO
DBCC SHRINKFILE (N'MSDBLog' , 0)
GO

-------------------------------------------------------------------