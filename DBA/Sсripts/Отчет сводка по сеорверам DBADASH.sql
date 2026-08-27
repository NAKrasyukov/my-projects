USE DBADashDB;
GO

SET NOCOUNT ON;

------------------------------------------------------------
-- PARAMETERS
------------------------------------------------------------

DECLARE @DateTo datetime2(0) = GETDATE();

-- Последние 4 месяца от текущей даты
DECLARE @DateFrom datetime2(0) = DATEADD(MONTH, -4, @DateTo);

-- Если нужны фиксированные даты, например:
-- SET @DateFrom = '2026-05-01 00:00:00';
-- SET @DateTo   = '2026-08-27 23:59:59';


------------------------------------------------------------
-- 1. SERVER SUMMARY
------------------------------------------------------------

;WITH CPUData AS
(
    SELECT
        c.InstanceID,

        -- Средний SQL CPU
        AVG(
            CAST(c.SumSQLProcessCPU AS decimal(18,4))
            / NULLIF(c.SampleCount, 0)
        ) AS AvgSQLCPU,

        -- Средний максимальный общий CPU за час
        AVG(CAST(c.MaxTotalCPU AS decimal(18,4))) AS AvgMaxTotalCPU,

        -- Максимальный CPU за весь период
        MAX(c.MaxTotalCPU) AS MaxTotalCPU,

        -- Максимальный SQL CPU
        MAX(c.MaxSQLProcessCPU) AS MaxSQLCPU,

        -- Часов с CPU > 80%
        SUM(
            CASE WHEN c.MaxTotalCPU >= 80 THEN 1 ELSE 0 END
        ) AS HoursCPUOver80,

        -- Часов с CPU > 90%
        SUM(
            CASE WHEN c.MaxTotalCPU >= 90 THEN 1 ELSE 0 END
        ) AS HoursCPUOver90,

        COUNT(*) AS CPUHours

    FROM dbo.CPU_60MIN c
    WHERE c.EventTime >= @DateFrom
      AND c.EventTime <  @DateTo
    GROUP BY
        c.InstanceID
),

RAMData AS
(
    SELECT
        p.InstanceID,

        -- Средний % использования RAM
        AVG(
            CAST(
                100.0
                * (
                    CAST(i.physical_memory_kb AS decimal(20,4))
                    - CAST(p.Value_Total AS decimal(20,4))
                )
                / NULLIF(i.physical_memory_kb, 0)
                AS decimal(18,4)
            )
        ) AS AvgRAMUsedPct,

        -- Максимальный % использования RAM
        MAX(
            CAST(
                100.0
                * (
                    CAST(i.physical_memory_kb AS decimal(20,4))
                    - CAST(p.Value_Min AS decimal(20,4))
                )
                / NULLIF(i.physical_memory_kb, 0)
                AS decimal(18,4)
            )
        ) AS MaxRAMUsedPct,

        -- Количество часов RAM >= 80%
        SUM(
            CASE
                WHEN
                    100.0
                    * (
                        CAST(i.physical_memory_kb AS decimal(20,4))
                        - CAST(p.Value_Min AS decimal(20,4))
                    )
                    / NULLIF(i.physical_memory_kb, 0)
                    >= 80
                THEN 1
                ELSE 0
            END
        ) AS HoursRAMOver80,

        -- Количество часов RAM >= 90%
        SUM(
            CASE
                WHEN
                    100.0
                    * (
                        CAST(i.physical_memory_kb AS decimal(20,4))
                        - CAST(p.Value_Min AS decimal(20,4))
                    )
                    / NULLIF(i.physical_memory_kb, 0)
                    >= 90
                THEN 1
                ELSE 0
            END
        ) AS HoursRAMOver90,

        COUNT(*) AS RAMHours

    FROM dbo.PerformanceCounters_60MIN p
    INNER JOIN dbo.Instances i
        ON i.InstanceID = p.InstanceID

    WHERE p.CounterID = 3
      AND p.SnapshotDate >= @DateFrom
      AND p.SnapshotDate <  @DateTo

    GROUP BY
        p.InstanceID,
        i.physical_memory_kb
),

------------------------------------------------------------
-- Последний снимок диска за период
------------------------------------------------------------

LastDrive AS
(
    SELECT
        d.InstanceID,
        ds.DriveID,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY d.DriveID
            ORDER BY ds.SnapshotDate DESC
        ) AS rn

    FROM dbo.DriveSnapshot ds

    INNER JOIN dbo.Drives d
        ON d.DriveID = ds.DriveID

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate <  @DateTo
),

------------------------------------------------------------
-- Диски в начале периода
------------------------------------------------------------

FirstDrive AS
(
    SELECT
        d.InstanceID,
        ds.DriveID,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY d.DriveID
            ORDER BY ds.SnapshotDate ASC
        ) AS rn

    FROM dbo.DriveSnapshot ds

    INNER JOIN dbo.Drives d
        ON d.DriveID = ds.DriveID

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate <  @DateTo
),

DiskData AS
(
    SELECT
        l.InstanceID,

        -- Общее пространство всех дисков
        SUM(l.Capacity) AS TotalDiskCapacity,

        SUM(l.UsedSpace) AS TotalDiskUsed,

        SUM(l.FreeSpace) AS TotalDiskFree,

        -- Количество дисков с использованием >= 80%
        SUM(
            CASE
                WHEN
                    100.0 * l.UsedSpace
                    / NULLIF(l.Capacity, 0) >= 80
                THEN 1
                ELSE 0
            END
        ) AS DrivesOver80,

        -- Количество дисков с использованием >= 90%
        SUM(
            CASE
                WHEN
                    100.0 * l.UsedSpace
                    / NULLIF(l.Capacity, 0) >= 90
                THEN 1
                ELSE 0
            END
        ) AS DrivesOver90,

        -- Изменение свободного пространства
        SUM(
            l.FreeSpace - f.FreeSpace
        ) AS FreeSpaceChange

    FROM LastDrive l

    LEFT JOIN FirstDrive f
        ON f.DriveID = l.DriveID
       AND f.rn = 1

    WHERE l.rn = 1

    GROUP BY
        l.InstanceID
)

SELECT
    i.InstanceID,

    i.InstanceDisplayName AS ServerName,

    i.ServerName AS SQLServer,

    i.MachineName,

    i.Edition,

    i.ProductVersion,

    --------------------------------------------------------
    -- HARDWARE
    --------------------------------------------------------

    CAST(
        i.physical_memory_kb / 1024.0 / 1024.0
        AS decimal(10,2)
    ) AS RAM_GB,

    i.cpu_count AS CPU_Count,

    --------------------------------------------------------
    -- CPU
    --------------------------------------------------------

    CAST(c.AvgSQLCPU AS decimal(10,2))
        AS Avg_SQL_CPU_Pct,

    CAST(c.AvgMaxTotalCPU AS decimal(10,2))
        AS Avg_Hourly_Max_CPU_Pct,

    c.MaxSQLCPU
        AS Max_SQL_CPU_Pct,

    c.MaxTotalCPU
        AS Max_Total_CPU_Pct,

    c.HoursCPUOver80
        AS CPU_Hours_Over80,

    c.HoursCPUOver90
        AS CPU_Hours_Over90,

    c.CPUHours
        AS CPU_Hours_Collected,

    --------------------------------------------------------
    -- RAM
    --------------------------------------------------------

    CAST(r.AvgRAMUsedPct AS decimal(10,2))
        AS Avg_RAM_Used_Pct,

    CAST(r.MaxRAMUsedPct AS decimal(10,2))
        AS Max_RAM_Used_Pct,

    r.HoursRAMOver80
        AS RAM_Hours_Over80,

    r.HoursRAMOver90
        AS RAM_Hours_Over90,

    r.RAMHours
        AS RAM_Hours_Collected,

    --------------------------------------------------------
    -- DISKS
    --------------------------------------------------------

    CAST(
        d.TotalDiskCapacity / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Disk_Capacity_GB,

    CAST(
        d.TotalDiskUsed / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Disk_Used_GB,

    CAST(
        d.TotalDiskFree / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Disk_Free_GB,

    CAST(
        100.0 * d.TotalDiskUsed
        / NULLIF(d.TotalDiskCapacity, 0)
        AS decimal(10,2)
    ) AS Disk_Used_Pct,

    CAST(
        d.FreeSpaceChange / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Disk_FreeSpace_Change_GB,

    d.DrivesOver80
        AS Drives_Over80,

    d.DrivesOver90
        AS Drives_Over90

FROM dbo.Instances i

LEFT JOIN CPUData c
    ON c.InstanceID = i.InstanceID

LEFT JOIN RAMData r
    ON r.InstanceID = i.InstanceID

LEFT JOIN DiskData d
    ON d.InstanceID = i.InstanceID

WHERE i.IsActive = 1
  AND i.ShowInSummary = 1

ORDER BY
    i.InstanceDisplayName;


------------------------------------------------------------
-- 2. MONTHLY PERFORMANCE TREND
------------------------------------------------------------

;WITH CPU AS
(
    SELECT
        c.InstanceID,

        DATEFROMPARTS(
            YEAR(c.EventTime),
            MONTH(c.EventTime),
            1
        ) AS MonthDate,

        AVG(
            CAST(c.SumSQLProcessCPU AS decimal(18,4))
            / NULLIF(c.SampleCount, 0)
        ) AS AvgSQLCPU,

        AVG(
            CAST(c.MaxTotalCPU AS decimal(18,4))
        ) AS AvgTotalCPU,

        MAX(c.MaxTotalCPU) AS MaxTotalCPU

    FROM dbo.CPU_60MIN c

    WHERE c.EventTime >= @DateFrom
      AND c.EventTime < @DateTo

    GROUP BY
        c.InstanceID,
        DATEFROMPARTS(
            YEAR(c.EventTime),
            MONTH(c.EventTime),
            1
        )
),

RAM AS
(
    SELECT
        p.InstanceID,

        DATEFROMPARTS(
            YEAR(p.SnapshotDate),
            MONTH(p.SnapshotDate),
            1
        ) AS MonthDate,

        AVG(
            100.0 *
            (
                CAST(i.physical_memory_kb AS decimal(20,4))
                - CAST(p.Value_Total AS decimal(20,4))
            )
            / NULLIF(i.physical_memory_kb, 0)
        ) AS AvgRAMUsedPct,

        MAX(
            100.0 *
            (
                CAST(i.physical_memory_kb AS decimal(20,4))
                - CAST(p.Value_Min AS decimal(20,4))
            )
            / NULLIF(i.physical_memory_kb, 0)
        ) AS MaxRAMUsedPct

    FROM dbo.PerformanceCounters_60MIN p

    INNER JOIN dbo.Instances i
        ON i.InstanceID = p.InstanceID

    WHERE p.CounterID = 3
      AND p.SnapshotDate >= @DateFrom
      AND p.SnapshotDate < @DateTo

    GROUP BY
        p.InstanceID,
        DATEFROMPARTS(
            YEAR(p.SnapshotDate),
            MONTH(p.SnapshotDate),
            1
        )
)

SELECT
    i.InstanceDisplayName AS ServerName,

    COALESCE(
        c.MonthDate,
        r.MonthDate
    ) AS Month,

    CAST(c.AvgSQLCPU AS decimal(10,2))
        AS Avg_SQL_CPU_Pct,

    CAST(c.AvgTotalCPU AS decimal(10,2))
        AS Avg_Total_CPU_Pct,

    c.MaxTotalCPU
        AS Max_Total_CPU_Pct,

    CAST(r.AvgRAMUsedPct AS decimal(10,2))
        AS Avg_RAM_Used_Pct,

    CAST(r.MaxRAMUsedPct AS decimal(10,2))
        AS Max_RAM_Used_Pct

FROM dbo.Instances i

LEFT JOIN CPU c
    ON c.InstanceID = i.InstanceID

FULL OUTER JOIN RAM r
    ON r.InstanceID = i.InstanceID
   AND r.MonthDate = c.MonthDate

WHERE i.IsActive = 1
  AND i.ShowInSummary = 1

ORDER BY
    i.InstanceDisplayName,
    Month;


------------------------------------------------------------
-- 3. DISK REPORT
------------------------------------------------------------

;WITH FirstSnapshot AS
(
    SELECT
        d.InstanceID,
        d.DriveID,
        d.Name AS Drive,

        ds.SnapshotDate,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY d.DriveID
            ORDER BY ds.SnapshotDate ASC
        ) AS rn

    FROM dbo.DriveSnapshot ds

    INNER JOIN dbo.Drives d
        ON d.DriveID = ds.DriveID

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate < @DateTo
),

LastSnapshot AS
(
    SELECT
        d.InstanceID,
        d.DriveID,
        d.Name AS Drive,

        ds.SnapshotDate,
        ds.Capacity,
        ds.FreeSpace,
        ds.UsedSpace,

        ROW_NUMBER() OVER
        (
            PARTITION BY d.DriveID
            ORDER BY ds.SnapshotDate DESC
        ) AS rn

    FROM dbo.DriveSnapshot ds

    INNER JOIN dbo.Drives d
        ON d.DriveID = ds.DriveID

    WHERE ds.SnapshotDate >= @DateFrom
      AND ds.SnapshotDate < @DateTo
)

SELECT
    i.InstanceDisplayName AS ServerName,

    l.Drive,

    --------------------------------------------------------
    -- START
    --------------------------------------------------------

    CAST(
        f.Capacity / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Start_Capacity_GB,

    CAST(
        f.UsedSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Start_Used_GB,

    CAST(
        f.FreeSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Start_Free_GB,

    CAST(
        100.0 * f.UsedSpace
        / NULLIF(f.Capacity, 0)
        AS decimal(10,2)
    ) AS Start_Used_Pct,

    --------------------------------------------------------
    -- END
    --------------------------------------------------------

    CAST(
        l.Capacity / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS End_Capacity_GB,

    CAST(
        l.UsedSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS End_Used_GB,

    CAST(
        l.FreeSpace / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS End_Free_GB,

    CAST(
        100.0 * l.UsedSpace
        / NULLIF(l.Capacity, 0)
        AS decimal(10,2)
    ) AS End_Used_Pct,

    --------------------------------------------------------
    -- CHANGE
    --------------------------------------------------------

    CAST(
        (l.UsedSpace - f.UsedSpace)
        / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS Used_Growth_GB,

    CAST(
        (l.FreeSpace - f.FreeSpace)
        / 1024.0 / 1024.0 / 1024.0
        AS decimal(18,2)
    ) AS FreeSpace_Change_GB,

    l.SnapshotDate AS LastSnapshot

FROM LastSnapshot l

INNER JOIN FirstSnapshot f
    ON f.DriveID = l.DriveID
   AND f.rn = 1

INNER JOIN dbo.Instances i
    ON i.InstanceID = l.InstanceID

WHERE l.rn = 1
  AND i.IsActive = 1
  AND i.ShowInSummary = 1

ORDER BY
    i.InstanceDisplayName,
    l.Drive;