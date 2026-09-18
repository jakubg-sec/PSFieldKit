function Get-ADDnsForwarders {
    $ServerName = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $ForwarderConfiguration = Get-DnsServerForwarder `
            -ComputerName $ServerName `
            -ErrorAction Stop

        Write-Host "`nDNS Forwarders" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan
        Write-Host "Server        : $ServerName"
        Write-Host "Use Root Hints: $($ForwarderConfiguration.UseRootHint)"
        Write-Host ""

        if (-not $ForwarderConfiguration.IPAddress) {
            Write-Host "No DNS forwarders configured." -ForegroundColor Yellow
            return
        }

        $Forwarders = foreach ($Forwarder in $ForwarderConfiguration.IPAddress) {
            [PSCustomObject]@{
                Forwarder = $Forwarder.IPAddressToString
                Timeout   = $Forwarder.Timeout
            }
        }

        $Forwarders |
            Format-Table `
                Forwarder,
                Timeout `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve DNS forwarders." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}