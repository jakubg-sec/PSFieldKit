function Get-ADDnsScavenging {
    $ServerName = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Scavenging = Get-DnsServerScavenging `
            -ComputerName $ServerName `
            -ErrorAction Stop

        Write-Host "`nDNS Scavenging Configuration" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan
        Write-Host "Server: $ServerName"
        Write-Host ""

        Write-Host "Server Settings" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        [PSCustomObject]@{
            ScavengingState   = $Scavenging.ScavengingState
            NoRefreshInterval  = $Scavenging.NoRefreshInterval
            RefreshInterval    = $Scavenging.RefreshInterval
            ScavengingInterval = $Scavenging.ScavengingInterval
        } | Format-List

        Write-Host "`nZone Aging Settings" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan

        $Zones = Get-DnsServerZone `
            -ComputerName $ServerName `
            -ErrorAction Stop |
            Where-Object {
                $_.ZoneType -eq 'Primary' -and
                -not $_.IsAutoCreated
            }

        if (-not $Zones) {
            Write-Host "No primary DNS zones found." -ForegroundColor Yellow
            return
        }

        $ZoneResults = foreach ($Zone in $Zones) {
            try {
                $Aging = Get-DnsServerZoneAging `
                    -ComputerName $ServerName `
                    -Name $Zone.ZoneName `
                    -ErrorAction Stop

                [PSCustomObject]@{
                    ZoneName          = $Zone.ZoneName
                    AgingEnabled      = $Aging.AgingEnabled
                    NoRefreshInterval = $Aging.NoRefreshInterval
                    RefreshInterval   = $Aging.RefreshInterval
                    ScavengeServers   = if ($Aging.ScavengeServers) {
                        $Aging.ScavengeServers -join ', '
                    }
                    else {
                        'All authoritative servers'
                    }
                    Status = if ($Aging.AgingEnabled) {
                        'ENABLED'
                    }
                    else {
                        'DISABLED'
                    }
                }
            }
            catch {
                [PSCustomObject]@{
                    ZoneName          = $Zone.ZoneName
                    AgingEnabled      = 'Unknown'
                    NoRefreshInterval = 'N/A'
                    RefreshInterval   = 'N/A'
                    ScavengeServers   = 'N/A'
                    Status            = 'ERROR'
                }
            }
        }

        $ZoneResults |
            Sort-Object ZoneName |
            Format-Table `
                ZoneName,
                AgingEnabled,
                NoRefreshInterval,
                RefreshInterval,
                ScavengeServers,
                Status `
                -Wrap `
                -AutoSize

        Write-Host ""

        $ServerEnabled = $Scavenging.ScavengingState -eq $true

        $EnabledZones = @(
            $ZoneResults |
            Where-Object {
                $_.AgingEnabled -eq $true
            }
        )

        $DisabledZones = @(
            $ZoneResults |
            Where-Object {
                $_.AgingEnabled -eq $false
            }
        )

        if (-not $ServerEnabled) {
            Write-Host "Server-level DNS scavenging is disabled." -ForegroundColor Yellow
        }
        elseif ($DisabledZones.Count -gt 0) {
            Write-Host "Server scavenging is enabled, but aging is disabled on one or more zones." -ForegroundColor Yellow
        }
        else {
            Write-Host "DNS scavenging and zone aging are enabled." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to retrieve DNS scavenging configuration." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}