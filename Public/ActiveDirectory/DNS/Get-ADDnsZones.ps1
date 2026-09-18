function Get-ADDnsZones {
    $ServerName = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Zones = Get-DnsServerZone `
            -ComputerName $ServerName `
            -ErrorAction Stop

        if (-not $Zones) {
            Write-Host "`nNo DNS zones found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nDNS Zones" -ForegroundColor Cyan
        Write-Host "---------" -ForegroundColor DarkCyan
        Write-Host "Server: $ServerName"
        Write-Host ""

        $Results = foreach ($Zone in $Zones) {
            [PSCustomObject]@{
                ZoneName             = $Zone.ZoneName
                ZoneType             = $Zone.ZoneType
                IsDsIntegrated       = $Zone.IsDsIntegrated
                IsReverseLookupZone  = $Zone.IsReverseLookupZone
                DynamicUpdate        = $Zone.DynamicUpdate
                ReplicationScope     = $Zone.ReplicationScope
                ReadOnly             = $Zone.ReadOnly
                DirectoryPartition   = $Zone.DirectoryPartitionName
            }
        }

        $Results |
            Sort-Object IsReverseLookupZone, ZoneName |
            Format-Table `
                ZoneName,
                ZoneType,
                IsDsIntegrated,
                IsReverseLookupZone,
                DynamicUpdate,
                ReplicationScope,
                ReadOnly `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve DNS zones." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}