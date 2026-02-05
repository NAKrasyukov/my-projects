SELECT 
    j.name,
    COUNT(*) AS cnt
FROM dbo.sysjobhistory h
JOIN dbo.sysjobs j ON h.job_id = j.job_id
GROUP BY j.name
ORDER BY cnt DESC;



Select top(1)run_date from dbo.sysjobhistory
order by run_date 