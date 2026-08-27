/*
==========================================================================
 DBA Dash - Performance Report
 CPU / RAM / Disk Space / Disk I/O

 База: DBADashDB

 По умолчанию:
   @DateFrom = 4 месяца назад
   @DateTo   = текущая дата/время

 При необходимости даты можно задать вручную.
==========================================================================
*/

USE DBADashDB;
GO

SET NOCOUNT ON;

DECLARE @DateFrom datetime2(0) = DATEADD(MONTH, -4, GETDATE());
DECLARE @DateTo   datetime2(0) = GETDATE();


/*
==========================================================================
 1. SERVER SUMMARY
==========================================================================
*/

;WITH CPU_Hourly AS
(
    SELECT
        c.InstanceID,
        c.EventTime,

        CAST(
            c.SumSQLProcessCPU * 1.0 /
            NULLIF(c.SampleCount, 0)
            AS decimal(10,2)
        ) AS AvgSQLCPU,

        CAST(
            c.SumTotalCPU * 1.0 /
            NULLIF(c.SampleCount, 0)
            AS decimal(10,2)
        ) AS AvgTotalCPU,

        c.MaxSQLProcessCPU,
        c.MaxTotalCPU
    FROM dbo.CPU_60MIN AS c
    WHERE c.EventTime >= @DateFrom
      AND c.EventTime <  @DateTo
),
CPU_Summary AS
(
    SELECT
        InstanceID,

        AVG(AvgSQLCPU) AS AvgSQLCPU,
        AVG(AvgTotalCPU) AS AvgTotalCPU,

        MAX(MaxSQLProcessCPU) AS MaxSQLCPU,
        MAX(MaxTotalCPU) AS MaxTotalCPU,

        SUM(
            CASE
                WHEN MaxTotalCPU >= 80 THEN 1
                ELSE 0
            END
        ) AS HoursCPU80Plus,

        SUM(
            CASE
                WHEN MaxTotalCPU >= 90 THEN 1
                ELSE 0
            END
        ) AS HoursCPU90Plus,

        COUNT(*) AS CPUHours

    FROM CPU_Hourly
    GROUP BY InstanceID
),

/*
--------------------------------------------------------------------------
 RAM
 -------------------------------------------------------------------------
 CounterID = 3
 sys.dm_os_sys_memory
 Available Physical Memory (KB)

 Сначала берем среднее Available Physical Memory за каждый час,
 затем рассчитываем процент использования RAM.

 ВАЖНО:
 Не используем p.Value и не используем смешивание разных counters.
--------------------------------------------------------------------------
*/

RAM_Hourly AS
(
    SELECT
        p.InstanceID,
        p.SnapshotDate,

        /*
          Value_Total = сумма значений counter-а за час.
          Поэтому сначала получаем среднее значение:
              Value_Total / SampleCount

          CounterID = 3:
              Available Physical Memory (KB)
        */
        CAST(
            p.Value_Total * 1.0 /
            NULLIF(p.SampleCount, 0)
            AS decimal(19,4)
        ) AS AvailableMemoryKB,

        CAST(
            i.physical_memory_kb
            AS decimal(19,4)
        ) AS PhysicalMemoryKB

    FROM dbo.PerformanceCounters_60MIN AS p

    INNER JOIN dbo.Instances AS i
        ON i.InstanceID = p.InstanceID

    WHERE p.CounterID = 3
      AND p.SnapshotDate >= @DateFrom
      AND p.SnapshotDate <  @DateTo
      AND i.physical_memory_kb > 0
      AND p.SampleCount > 0
),
RAM_Calculated AS
(
    SELECT
        InstanceID,
        SnapshotDate,

        CASE
            WHEN AvailableMemoryKB IS NULL
                THEN NULL

            /*
              Если Available Memory больше физической RAM,
              такое значение считаем некорректным.
            */
            WHEN AvailableMemoryKB < 0
                THEN NULL

            WHEN AvailableMemoryKB > PhysicalMemoryKB
                THEN NULL

            ELSE
                (
                    PhysicalMemoryKB -
                    AvailableMemoryKB
                ) * 100.0 /
                PhysicalMemoryKB

        END AS RAMUsedPct

    FROM RAM_Hourly
),
RAM_Summary AS
(
    SELECT
        InstanceID,

        AVG(RAMUsedPct) AS AvgRAMUsedPct,

        MAX(RAMUsedPct) AS MaxRAMUsedPct,

        SUM(
            CASE
                WHEN RAMUsedPct >= 80
                    THEN 1
                ELSE 0
            END
        ) AS HoursRAM80Plus,

        SUM(
            CASE
                WHEN RAMUsedPct >= 90
                    THEN 1
                ELSE 0
            END
        ) AS HoursRAM90Plus,

        COUNT(RAMUsedPct) AS RAMHours

    FROM RAM_Calculated

    GROUP BY InstanceID
)
SELECT
    i.InstanceID,

    COALESCE(
        NULLIF(i.InstanceDisplayName, ''),
        NULLIF(i.ServerName, ''),
        i.Instance
    ) AS ServerName,

    i.MachineName,
    i.InstanceName,

    i.Edition,
    i.ProductVersion,

    /*
    CPU
    */
    CAST(cs.AvgSQLCPU AS decimal(10,2))
        AS AvgSQLCPU_Percent,

    CAST(cs.AvgTotalCPU AS decimal(10,2))
        AS AvgTotalCPU_Percent,

    cs.MaxSQLCPU
        AS MaxSQLCPU_Percent,

    cs.MaxTotalCPU
        AS MaxTotalCPU_Percent,

    cs.HoursCPU80Plus,
    cs.HoursCPU90Plus,
    cs.CPUHours,

    /*
    RAM
    */
    CAST(
        i.physical_memory_kb / 1024.0 / 1024.0
        AS decimal(12,2)
    ) AS PhysicalRAM_GB,

    CAST(
        rs.AvgRAMUsedPct
        AS decimal(10,2)
    ) AS AvgRAMUsed_Percent,

    CAST(
        rs.MaxRAMUsedPct
        AS decimal(10,2)
    ) AS MaxRAMUsed_Percent,

    rs.HoursRAM80Plus,
    rs.HoursRAM90Plus,
    rs.RAMHours,

    /*
    Период отчета
    */
    @DateFrom AS ReportFrom,
    @DateTo   AS ReportTo

FROM dbo.Instances AS i

LEFT JOIN CPU_Summary AS cs
    ON cs.InstanceID = i.InstanceID

LEFT JOIN RAM_Summary AS rs
    ON rs.InstanceID = i.InstanceID

WHERE i.IsActive = 1
  AND ISNULL(i.ShowInSummary, 1) = 1

ORDER BY
    ServerName;


/*
==========================================================================
 2. DISK SPACE SUMMARY
==========================================================================
*/

;WITH FirstSnapshot AS
(
    SELECT
        ds.DriveID,
        ds.SnapshotDate,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY ds.DriveID
            ORDER BY ds.SnapshotDate ASC
        ) AS rn

    FROM dbo.DriveSnapshot AS ds

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate <  @DateTo
),
LastSnapshot AS
(
    SELECT
        ds.DriveID,
        ds.SnapshotDate,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY ds.DriveID
            ORDER BY ds.SnapshotDate DESC
        ) AS rn

    FROM dbo.DriveSnapshot AS ds

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate <  @DateTo
)

SELECT
    i.InstanceID,

    COALESCE(
        NULLIF(i.InstanceDisplayName, ''),
        NULLIF(i.ServerName, ''),
        i.Instance
    ) AS ServerName,

    d.Name AS Drive,

    /*
      Начало периода
    */
    CAST(
        fs.Capacity / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS StartCapacity_GB,

    CAST(
        fs.UsedSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS StartUsed_GB,

    CAST(
        fs.FreeSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS StartFree_GB,

    CAST(
        CASE
            WHEN fs.Capacity > 0
            THEN fs.UsedSpace * 100.0 / fs.Capacity
        END
        AS decimal(10,2)
    ) AS StartUsed_Percent,

    /*
      Конец периода
    */
    CAST(
        ls.Capacity / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS EndCapacity_GB,

    CAST(
        ls.UsedSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS EndUsed_GB,

    CAST(
        ls.FreeSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS EndFree_GB,

    CAST(
        CASE
            WHEN ls.Capacity > 0
            THEN ls.UsedSpace * 100.0 / ls.Capacity
        END
        AS decimal(10,2)
    ) AS EndUsed_Percent,

    /*
      Изменение
    */
    CAST(
        (
            ls.FreeSpace - fs.FreeSpace
        ) / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS FreeSpaceChange_GB,

    CAST(
        (
            ls.UsedSpace - fs.UsedSpace
        ) / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS UsedSpaceChange_GB,

    fs.SnapshotDate AS StartSnapshotDate,
    ls.SnapshotDate AS EndSnapshotDate

FROM FirstSnapshot AS fs

INNER JOIN LastSnapshot AS ls
    ON ls.DriveID = fs.DriveID
   AND fs.rn = 1
   AND ls.rn = 1

INNER JOIN dbo.Drives AS d
    ON d.DriveID = fs.DriveID

INNER JOIN dbo.Instances AS i
    ON i.InstanceID = d.InstanceID

WHERE i.IsActive = 1
  AND ISNULL(i.ShowInSummary, 1) = 1

ORDER BY
    ServerName,
    d.Name;


/*
==========================================================================
 3. DISK I/O SUMMARY
==========================================================================
*/

SELECT
    i.InstanceID,

    COALESCE(
        NULLIF(i.InstanceDisplayName, ''),
        NULLIF(i.ServerName, ''),
        i.Instance
    ) AS ServerName,

    io.Drive,

    CAST(
        MAX(io.MaxIOPs)
        AS decimal(18,2)
    ) AS MaxIOPS,

    CAST(
        MAX(io.MaxReadIOPs)
        AS decimal(18,2)
    ) AS MaxReadIOPS,

    CAST(
        MAX(io.MaxWriteIOPs)
        AS decimal(18,2)
    ) AS MaxWriteIOPS,

    CAST(
        MAX(io.MaxMBsec)
        AS decimal(18,2)
    ) AS MaxMBsec,

    CAST(
        MAX(io.MaxReadMBsec)
        AS decimal(18,2)
    ) AS MaxReadMBsec,

    CAST(
        MAX(io.MaxWriteMBsec)
        AS decimal(18,2)
    ) AS MaxWriteMBsec,

    CAST(
        MAX(io.MaxLatency)
        AS decimal(18,2)
    ) AS MaxLatency_ms,

    CAST(
        MAX(io.MaxReadLatency)
        AS decimal(18,2)
    ) AS MaxReadLatency_ms,

    CAST(
        MAX(io.MaxWriteLatency)
        AS decimal(18,2)
    ) AS MaxWriteLatency_ms

FROM dbo.DBIOStats_60MIN AS io

INNER JOIN dbo.Instances AS i
    ON i.InstanceID = io.InstanceID

WHERE io.SnapshotDate >= @DateFrom
  AND io.SnapshotDate <  @DateTo
  AND i.IsActive = 1
  AND ISNULL(i.ShowInSummary, 1) = 1

GROUP BY
    i.InstanceID,
    i.InstanceDisplayName,
    i.ServerName,
    i.Instance,
    io.Drive

ORDER BY
    ServerName,
    io.Drive;


/*
==========================================================================
 4. MONTHLY TREND
==========================================================================
*/

;WITH CPU_Monthly AS
(
    SELECT
        c.InstanceID,

        DATEFROMPARTS(
            YEAR(c.EventTime),
            MONTH(c.EventTime),
            1
        ) AS ReportMonth,

        AVG(
            c.SumSQLProcessCPU * 1.0 /
            NULLIF(c.SampleCount, 0)
        ) AS AvgSQLCPU,

        AVG(
            c.SumTotalCPU * 1.0 /
            NULLIF(c.SampleCount, 0)
        ) AS AvgTotalCPU,

        MAX(c.MaxTotalCPU) AS MaxTotalCPU,

        SUM(
            CASE
                WHEN c.MaxTotalCPU >= 80 THEN 1
                ELSE 0
            END
        ) AS CPU80Hours,

        SUM(
            CASE
                WHEN c.MaxTotalCPU >= 90 THEN 1
                ELSE 0
            END
        ) AS CPU90Hours

    FROM dbo.CPU_60MIN AS c

    WHERE c.EventTime >= @DateFrom
      AND c.EventTime <  @DateTo

    GROUP BY
        c.InstanceID,
        DATEFROMPARTS(
            YEAR(c.EventTime),
            MONTH(c.EventTime),
            1
        )
),

/*
--------------------------------------------------------------------------
 RAM Monthly

 CounterID = 3
 Available Physical Memory (KB)

 Сначала берем hourly Value_Total.
 Затем внутри месяца считаем Avg/Max RAM usage.
--------------------------------------------------------------------------
*/

RAM_Monthly AS
(
    SELECT
        p.InstanceID,

        DATEFROMPARTS(
            YEAR(p.SnapshotDate),
            MONTH(p.SnapshotDate),
            1
        ) AS ReportMonth,

        AVG(
            CASE
                WHEN i.physical_memory_kb > 0
                 AND p.SampleCount > 0
                 AND
                    (
                        p.Value_Total * 1.0 /
                        p.SampleCount
                    ) BETWEEN 0 AND i.physical_memory_kb
                THEN
                    (
                        i.physical_memory_kb
                        -
                        (
                            p.Value_Total * 1.0 /
                            p.SampleCount
                        )
                    ) * 100.0
                    / i.physical_memory_kb
            END
        ) AS AvgRAMUsedPct,

        MAX(
            CASE
                WHEN i.physical_memory_kb > 0
                 AND p.SampleCount > 0
                 AND
                    (
                        p.Value_Total * 1.0 /
                        p.SampleCount
                    ) BETWEEN 0 AND i.physical_memory_kb
                THEN
                    (
                        i.physical_memory_kb
                        -
                        (
                            p.Value_Total * 1.0 /
                            p.SampleCount
                        )
                    ) * 100.0
                    / i.physical_memory_kb
            END
        ) AS MaxRAMUsedPct,

        SUM(
            CASE
                WHEN i.physical_memory_kb > 0
                 AND p.SampleCount > 0
                 AND
                    (
                        p.Value_Total * 1.0 /
                        p.SampleCount
                    ) BETWEEN 0 AND i.physical_memory_kb
                 AND
                    (
                        (
                            i.physical_memory_kb
                            -
                            (
                                p.Value_Total * 1.0 /
                                p.SampleCount
                            )
                        ) * 100.0
                        / i.physical_memory_kb
                    ) >= 80
                THEN 1
                ELSE 0
            END
        ) AS RAM80Hours,

        SUM(
            CASE
                WHEN i.physical_memory_kb > 0
                 AND p.SampleCount > 0
                 AND
                    (
                        p.Value_Total * 1.0 /
                        p.SampleCount
                    ) BETWEEN 0 AND i.physical_memory_kb
                 AND
                    (
                        (
                            i.physical_memory_kb
                            -
                            (
                                p.Value_Total * 1.0 /
                                p.SampleCount
                            )
                        ) * 100.0
                        / i.physical_memory_kb
                    ) >= 90
                THEN 1
                ELSE 0
            END
        ) AS RAM90Hours

    FROM dbo.PerformanceCounters_60MIN AS p

    INNER JOIN dbo.Instances AS i
        ON i.InstanceID = p.InstanceID

    WHERE p.CounterID = 3
      AND p.SnapshotDate >= @DateFrom
      AND p.SnapshotDate <  @DateTo

    GROUP BY
        p.InstanceID,
        DATEFROMPARTS(
            YEAR(p.SnapshotDate),
            MONTH(p.SnapshotDate),
            1
        )
)

SELECT
    i.InstanceID,

    COALESCE(
        NULLIF(i.InstanceDisplayName, ''),
        NULLIF(i.ServerName, ''),
        i.Instance
    ) AS ServerName,

    COALESCE(
        c.ReportMonth,
        r.ReportMonth
    ) AS ReportMonth,

    /*
    CPU
    */
    CAST(
        c.AvgSQLCPU
        AS decimal(10,2)
    ) AS AvgSQLCPU_Percent,

    CAST(
        c.AvgTotalCPU
        AS decimal(10,2)
    ) AS AvgTotalCPU_Percent,

    c.MaxTotalCPU
        AS MaxTotalCPU_Percent,

    ISNULL(c.CPU80Hours, 0)
        AS CPU80Hours,

    ISNULL(c.CPU90Hours, 0)
        AS CPU90Hours,

    /*
    RAM
    */
    CAST(
        r.AvgRAMUsedPct
        AS decimal(10,2)
    ) AS AvgRAMUsed_Percent,

    CAST(
        r.MaxRAMUsedPct
        AS decimal(10,2)
    ) AS MaxRAMUsed_Percent,

    ISNULL(r.RAM80Hours, 0)
        AS RAM80Hours,

    ISNULL(r.RAM90Hours, 0)
        AS RAM90Hours

FROM dbo.Instances AS i

LEFT JOIN CPU_Monthly AS c
    ON c.InstanceID = i.InstanceID

LEFT JOIN RAM_Monthly AS r
    ON r.InstanceID = i.InstanceID
   AND r.ReportMonth = c.ReportMonth

WHERE i.IsActive = 1
  AND ISNULL(i.ShowInSummary, 1) = 1
  AND COALESCE(
        c.ReportMonth,
        r.ReportMonth
      ) IS NOT NULL

ORDER BY
    ServerName,
    ReportMonth;