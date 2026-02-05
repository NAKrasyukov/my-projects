USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-PERFORMANCE', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-WHOISACTIVE', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-INTERNAL-ACTIONS', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-XES', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-INTERNAL-CHECKS', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-AG', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-AGENT-HISTORY', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-PROCS', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-REPORT-AZMONITOR', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-INTERNAL-CONFIG', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-INTERNAL-TRENDS', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-DISK-UTILISATION', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-INTERNAL-RETENTION', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-INDEXES', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SQLWATCH-LOGGER-SYSCONFIG', 
		@enabled=0, 
		@notify_level_email=2, 
		@notify_level_page=2
GO