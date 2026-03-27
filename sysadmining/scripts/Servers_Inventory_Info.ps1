$Servers = Get-Content "C:\1temp\servers.txt"
$Result  = @()

foreach ($Server in $Servers) {
    Write-Host "Processing $Server..." -ForegroundColor Cyan

    try {
        # OS
        $OS = Get-CimInstance Win32_OperatingSystem -ComputerName $Server

        # CPU
        $CPU = Get-CimInstance Win32_Processor -ComputerName $Server
        $PhysicalCores = ($CPU | Measure-Object NumberOfCores -Sum).Sum
        $LogicalCores  = ($CPU | Measure-Object NumberOfLogicalProcessors -Sum).Sum

        # RAM
        $RAM = Get-CimInstance Win32_ComputerSystem -ComputerName $Server
        $RAM_GB = [Math]::Round($RAM.TotalPhysicalMemory / 1GB, 2)

        # Disks
        $Disks = Get-CimInstance Win32_LogicalDisk -ComputerName $Server -Filter "DriveType=3"

        foreach ($Disk in $Disks) {
            $Result += [PSCustomObject]@{
                ServerName        = $Server
                OS_Name           = $OS.Caption
                OS_Version        = $OS.Version
                OS_Build          = $OS.BuildNumber
                PhysicalCores     = $PhysicalCores
                LogicalCores      = $LogicalCores
                RAM_GB            = $RAM_GB
                Disk              = $Disk.DeviceID
                DiskSize_GB       = [Math]::Round($Disk.Size / 1GB, 2)
                DiskFree_GB       = [Math]::Round($Disk.FreeSpace / 1GB, 2)
            }
        }
    }
    catch {
        $Result += [PSCustomObject]@{
            ServerName    = $Server
            OS_Name       = "ERROR"
            OS_Version    = "ERROR"
            OS_Build      = "ERROR"
            PhysicalCores = "ERROR"
            LogicalCores  = "ERROR"
            RAM_GB        = "ERROR"
            Disk          = "-"
            DiskSize_GB   = "-"
            DiskFree_GB   = "-"
        }
    }
}

# Экспорт в CSV
$Result | Export-Csv "C:\1temp\servers_inventory.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Inventory saved to servers_inventory.csv" -ForegroundColor Green