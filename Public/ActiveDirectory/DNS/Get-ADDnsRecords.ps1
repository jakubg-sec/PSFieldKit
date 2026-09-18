function Get-ADDnsRecords {
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

    Write-Host "`nSelect record type"
    Write-Host "[1] All"
    Write-Host "[2] A"
    Write-Host "[3] AAAA"
    Write-Host "[4] CNAME"
    Write-Host "[5] MX"
    Write-Host "[6] NS"
    Write-Host "[7] PTR"
    Write-Host "[8] SRV"
    Write-Host "[9] TXT"

    $TypeChoice = Read-Host "`nSelect option"

    switch ($TypeChoice) {
        '1' {
            $RecordType = $null
        }
        '2' {
            $RecordType = 'A'
        }
        '3' {
            $RecordType = 'AAAA'
        }
        '4' {
            $RecordType = 'CNAME'
        }
        '5' {
            $RecordType = 'MX'
        }
        '6' {
            $RecordType = 'NS'
        }
        '7' {
            $RecordType = 'PTR'
        }
        '8' {
            $RecordType = 'SRV'
        }
        '9' {
            $RecordType = 'TXT'
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            return
        }
    }

    try {
        $Parameters = @{
            ComputerName = $ServerName
            ZoneName     = $ZoneName
            ErrorAction  = 'Stop'
        }

        if ($RecordType) {
            $Parameters.Type = $RecordType
        }

        $Records = Get-DnsServerResourceRecord @Parameters

        if (-not $Records) {
            Write-Host "`nNo DNS records found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nDNS Records" -ForegroundColor Cyan
        Write-Host "-----------" -ForegroundColor DarkCyan
        Write-Host "Server : $ServerName"
        Write-Host "Zone   : $ZoneName"
        Write-Host "Type   : $(if ($RecordType) { $RecordType } else { 'All' })"
        Write-Host ""

        $Results = foreach ($Record in $Records) {
            $Data = switch ($Record.RecordType) {
                'A' {
                    $Record.RecordData.IPv4Address.IPAddressToString
                }
                'AAAA' {
                    $Record.RecordData.IPv6Address.IPAddressToString
                }
                'CNAME' {
                    $Record.RecordData.HostNameAlias
                }
                'NS' {
                    $Record.RecordData.NameServer
                }
                'PTR' {
                    $Record.RecordData.PtrDomainName
                }
                'MX' {
                    "Priority=$($Record.RecordData.Preference); MailServer=$($Record.RecordData.MailExchange)"
                }
                'SRV' {
                    "Priority=$($Record.RecordData.Priority); Weight=$($Record.RecordData.Weight); Port=$($Record.RecordData.Port); Target=$($Record.RecordData.DomainName)"
                }
                'TXT' {
                    $Record.RecordData.DescriptiveText -join ' '
                }
                default {
                    ($Record.RecordData | Out-String).Trim()
                }
            }

            [PSCustomObject]@{
                HostName  = $Record.HostName
                Type      = $Record.RecordType
                TTL       = $Record.TimeToLive
                Timestamp = $Record.Timestamp
                Data      = $Data
            }
        }

        $Results |
            Sort-Object HostName, Type |
            Format-Table `
                HostName,
                Type,
                TTL,
                Timestamp,
                Data `
                -Wrap `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve DNS records." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}