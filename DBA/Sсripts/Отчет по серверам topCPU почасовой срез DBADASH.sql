USE DBADashDB;
GO

SET NOCOUNT ON;

DECLARE @DateFrom datetime2(0) = DATEADD(MONTH, -4, GETDATE());
DECLARE @DateTo   datetime2(0) = GETDATE();
DECLARE @CPUThreshold decimal(5,2) = 80.0;


/*
==========================================================================
 CPU PEAK LOAD REPORT
 Показывает все часы, в которых CPU достигал 80% и выше
==========================================================================
*/

SELECT
    i.InstanceID,

    COALESCE(
        NULLIF(i.InstanceDisplayName, ''),
        NULLIF(i.ServerName, ''),
        i.Instance
    ) AS ServerName,

    c.EventTime AS PeakDateTime,

    CAST(
        c.SumTotalCPU * 1.0 /
        NULLIF(c.SampleCount, 0)
        AS decimal(10,2)
    ) AS AvgTotalCPU_Percent,

    CAST(
        c.SumSQLProcessCPU * 1.0 /
        NULLIF(c.SampleCount, 0)
        AS decimal(10,2)
    ) AS AvgSQLCPU_Percent,

    CAST(
        c.MaxTotalCPU
        AS decimal(10,2)
    ) AS MaxTotalCPU_Percent,

    CAST(
        c.MaxSQLProcessCPU
        AS decimal(10,2)
    ) AS MaxSQLCPU_Percent,

    c.SampleCount

FROM dbo.CPU_60MIN AS c

INNER JOIN dbo.Instances AS i
    ON i.InstanceID = c.InstanceID

WHERE c.EventTime >= @DateFrom
  AND c.EventTime <  @DateTo

  -- Пиковая нагрузка CPU 80% и выше
  AND c.MaxTotalCPU >= @CPUThreshold

  -- Только активные серверы
  AND i.IsActive = 1
  AND ISNULL(i.ShowInSummary, 1) = 1

ORDER BY
    c.EventTime DESC,
    c.MaxTotalCPU DESC,
    ServerName;