function Get-ADDnsServerInformation {
    $Identity = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Recursion = Get-DnsServerRecursion `
            -ComputerName $Identity `
            -ErrorAction Stop

        $Zones = @(
            Get-DnsServerZone `
                -ComputerName $Identity `
                -ErrorAction Stop
        )

        $ForwarderConfiguration = Get-DnsServerForwarder `
            -ComputerName $Identity `
            -ErrorAction Stop

        $Forwarders = @(
            $ForwarderConfiguration.IPAddress |
            Where-Object {
                $null -ne $_
            } |
            ForEach-Object {
                [string]$_
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
        )

        $ADIntegratedZones = @(
            $Zones |
            Where-Object {
                $_.IsDsIntegrated -eq $true
            }
        )

        $ReverseLookupZones = @(
            $Zones |
            Where-Object {
                $_.IsReverseLookupZone -eq $true
            }
        )

        Write-Host "`nDNS Server Information" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            ServerName            = $Identity
            ZoneCount             = $Zones.Count
            ADIntegratedZoneCount = $ADIntegratedZones.Count
            ReverseLookupZones    = $ReverseLookupZones.Count
            RecursionEnabled      = $Recursion.Enable
            ForwarderCount        = $Forwarders.Count
            Forwarders            = if ($Forwarders.Count -gt 0) {
                $Forwarders -join ', '
            }
            else {
                'None'
            }
            UseRootHints          = $ForwarderConfiguration.UseRootHint
        } | Format-List
    }
    catch {
        Write-Host "`nFailed to retrieve DNS server information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}