
SELECT 
    j.job_id as JobId,
    j.name AS JobName,
    SUSER_SNAME(j.owner_sid) AS JobOwner,
    'EXEC msdb.dbo.sp_update_job @job_id=N'''+cast(j.job_id as varchar(150))+''', @owner_login_name=N''sa''' as RunThisCodeToSetSA
FROM 
    msdb.dbo.sysjobs AS j
LEFT JOIN 
    master.dbo.syslogins AS l ON j.owner_sid = l.sid
WHERE 
    SUSER_SNAME(j.owner_sid) <> 'sa' OR SUSER_SNAME(j.owner_sid) IS NULL
ORDER BY 
    JobOwner, JobName;


