$Servers = Get-Content "C:\1temp\servers.txt"
$Result  = @()

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Import-Module SqlServer

foreach ($Server in $Servers) {

    Write-Host "Processing $Server..." -ForegroundColor Cyan

    try {

        # ---------------- OS ----------------
        $OS = Get-CimInstance Win32_OperatingSystem -ComputerName $Server
        $OS_Name    = $OS.Caption
        $OS_Version = $OS.Version
        $OS_Build   = $OS.BuildNumber

        # ---------------- CPU ----------------
        $CPU = Get-CimInstance Win32_Processor -ComputerName $Server
        $PhysicalCores = ($CPU | Measure-Object NumberOfCores -Sum).Sum
        $LogicalCores  = ($CPU | Measure-Object NumberOfLogicalProcessors -Sum).Sum

        # ---------------- RAM ----------------
        $RAM = Get-CimInstance Win32_ComputerSystem -ComputerName $Server
        $RAM_GB = [Math]::Round($RAM.TotalPhysicalMemory / 1GB, 2)

        # ---------------- DISKS ----------------
        $Disks = Get-CimInstance Win32_LogicalDisk -ComputerName $Server -Filter "DriveType=3"

        # ---------------- MSSQL ----------------
        $SQLVersion   = "NOT INSTALLED"
        $SQLEdition   = "-"
        $SQLLevel     = "-"
        $SQLInstance  = "-"

        try {
            $SqlQuery = @"
SELECT  
    SERVERPROPERTY('MachineName') AS MachineName,
    SERVERPROPERTY('InstanceName') AS InstanceName,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductMajorVersion') AS MajorVersion
"@

            $SqlInfo = Invoke-Sqlcmd -ServerInstance $Server -Query $SqlQuery -ErrorAction Stop -TrustServerCertificate

            if ($SqlInfo) {
                $SQLVersion  = $SqlInfo.ProductVersion
                $SQLEdition  = $SqlInfo.Edition
                $SQLLevel    = $SqlInfo.ProductLevel
                $SQLInstance = if ($SqlInfo.InstanceName) { $SqlInfo.InstanceName } else { "MSSQLSERVER" }
                $Major = [int]$SqlInfo.MajorVersion

                switch ($Major) {
                    16 { $MarketingVersion = "Microsoft SQL Server 2022 (64-bit)" }
                    15 { $MarketingVersion = "Microsoft SQL Server 2019 (64-bit)" }
                    14 { $MarketingVersion = "Microsoft SQL Server 2017 (64-bit)" }
                    13 { $MarketingVersion = "Microsoft SQL Server 2016 (64-bit)" }
                    12 { $MarketingVersion = "Microsoft SQL Server 2014 (64-bit)" }
                    11 { $MarketingVersion = "Microsoft SQL Server 2012 (64-bit)" }
                    default { $MarketingVersion = "Microsoft SQL Server (Unknown Version)" }
                }
            }
        }
        catch {
            # SQL не установлен или нет доступа
        }

        foreach ($Disk in $Disks) {
            $Result += [PSCustomObject]@{
                ServerName        = $Server
                OS_Name           = $OS_Name
                OS_Version        = $OS_Version
                OS_Build          = $OS_Build
                PhysicalCores     = $PhysicalCores
                LogicalCores      = $LogicalCores
                RAM_GB            = $RAM_GB
                SQL_Instance      = $SQLInstance
                SQL_MarketingVersion = $MarketingVersion
                SQL_Version       = $SQLVersion
                SQL_ProductLevel  = $SQLLevel
                SQL_Edition       = $SQLEdition
                Disk              = $Disk.DeviceID
                DiskSize_GB       = [Math]::Round($Disk.Size / 1GB, 2)
                DiskFree_GB       = [Math]::Round($Disk.FreeSpace / 1GB, 2)
            }
        }

    }
    catch {
        $Result += [PSCustomObject]@{
            ServerName        = $Server
            OS_Name           = "ERROR"
            OS_Version        = "ERROR"
            OS_Build          = "ERROR"
            PhysicalCores     = "ERROR"
            LogicalCores      = "ERROR"
            RAM_GB            = "ERROR"
            SQL_Instance      = "ERROR"
            SQL_Version       = "ERROR"
            SQL_ProductLevel  = "ERROR"
            SQL_Edition       = "ERROR"
            Disk              = "-"
            DiskSize_GB       = "-"
            DiskFree_GB       = "-"
        }
    }
}


# Экспорт в CSV
$Result | Export-Csv "C:\1temp\servers_inventorySQLversion.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Inventory saved to servers_inventory.csv" -ForegroundColor Green