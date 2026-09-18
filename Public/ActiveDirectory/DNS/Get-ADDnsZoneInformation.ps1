function Get-ADDnsZoneInformation {
    $ServerName = Read-Host "Enter DNS server name"

    if ([string]::IsNullOrWhiteSpace($ServerName)) {
        Write-Host "`nDNS server name cannot be empty." -ForegroundColor Red
        return
    }

    $ZoneName = Read-Host "Enter zone name"

    if ([string]::IsNullOrWhiteSpace($ZoneName)) {
        Write-Host "`nZone name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Zone = Get-DnsServerZone `
            -ComputerName $ServerName `
            -Name $ZoneName `
            -ErrorAction Stop

        Write-Host "`nDNS Zone Information" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Server : $ServerName"
        Write-Host "Zone   : $ZoneName"
        Write-Host ""

        $ZoneInformation = [PSCustomObject]@{
            ZoneName            = $Zone.ZoneName
            ZoneType            = $Zone.ZoneType
            IsDsIntegrated      = $Zone.IsDsIntegrated
            IsReverseLookupZone = $Zone.IsReverseLookupZone
            IsAutoCreated       = $Zone.IsAutoCreated
            DynamicUpdate       = $Zone.DynamicUpdate
            ReplicationScope    = $Zone.ReplicationScope
            DirectoryPartition  = $Zone.DirectoryPartitionName
            ReadOnly            = $Zone.ReadOnly
        }

        Write-Host "Zone Configuration" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $ZoneInformation | Format-List

        # SOA
        Write-Host "`nSOA Record" -ForegroundColor Cyan
        Write-Host "----------" -ForegroundColor DarkCyan

        try {
            $SOA = Get-DnsServerResourceRecord `
                -ComputerName $ServerName `
                -ZoneName $ZoneName `
                -RRType SOA `
                -ErrorAction Stop

            if ($SOA) {
                $SOA |
                    Select-Object `
                        HostName,
                        RecordType,
                        @{
                            Name = 'PrimaryServer'
                            Expression = {
                                $_.RecordData.PrimaryServer
                            }
                        },
                        @{
                            Name = 'ResponsiblePerson'
                            Expression = {
                                $_.RecordData.ResponsiblePerson
                            }
                        },
                        @{
                            Name = 'SerialNumber'
                            Expression = {
                                $_.RecordData.SerialNumber
                            }
                        },
                        @{
                            Name = 'RefreshInterval'
                            Expression = {
                                $_.RecordData.RefreshInterval
                            }
                        },
                        @{
                            Name = 'RetryDelay'
                            Expression = {
                                $_.RecordData.RetryDelay
                            }
                        },
                        @{
                            Name = 'ExpireLimit'
                            Expression = {
                                $_.RecordData.ExpireLimit
                            }
                        },
                        @{
                            Name = 'MinimumTTL'
                            Expression = {
                                $_.RecordData.MinimumTTL
                            }
                        } |
                    Format-List
            }
            else {
                Write-Host "SOA record not found." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Unable to retrieve SOA record." -ForegroundColor Yellow
        }

        # NS
        Write-Host "`nName Servers" -ForegroundColor Cyan
        Write-Host "------------" -ForegroundColor DarkCyan

        try {
            $NS = Get-DnsServerResourceRecord `
                -ComputerName $ServerName `
                -ZoneName $ZoneName `
                -RRType NS `
                -ErrorAction Stop

            if ($NS) {
                $NS |
                    Select-Object `
                        HostName,
                        @{
                            Name = 'NameServer'
                            Expression = {
                                $_.RecordData.NameServer
                            }
                        } |
                    Format-Table -AutoSize
            }
            else {
                Write-Host "No NS records found." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Unable to retrieve NS records." -ForegroundColor Yellow
        }

        # Aging / Scavenging
        Write-Host "`nAging / Scavenging" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        try {
            $Aging = Get-DnsServerZoneAging `
                -ComputerName $ServerName `
                -Name $ZoneName `
                -ErrorAction Stop

            $Aging |
                Format-List
        }
        catch {
            Write-Host "Aging information is not available for this zone." `
                -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nFailed to retrieve DNS zone information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}