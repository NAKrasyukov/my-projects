$Servers = Get-Content "C:\1temp\servers.txt"

$result = foreach ($server in $Servers) {
    try {
        $ips = Resolve-DnsName $server -ErrorAction Stop |
               Where-Object { $_.Type -eq 'A' } |
               Select-Object -ExpandProperty IPAddress

        foreach ($ip in $ips) {
            [PSCustomObject]@{
                ServerName = $server
                IPAddress  = $ip
            }
        }
    }
    catch {
        [PSCustomObject]@{
            ServerName = $server
            IPAddress  = "NOT RESOLVED"
        }
    }
}

$result | Export-Csv "C:\1temp\servers_with_ip.csv" -NoTypeInformation -Encoding UTF8