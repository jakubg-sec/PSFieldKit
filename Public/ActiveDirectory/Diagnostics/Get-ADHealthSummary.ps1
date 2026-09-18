function Get-ADHealthSummary {
    try {
        $Results = @()

        Write-Host "`nActive Directory Health Summary" -ForegroundColor Cyan
        Write-Host "-------------------------------" -ForegroundColor DarkCyan

        $Domain = Get-ADDomain -ErrorAction Stop
        $Forest = Get-ADForest -ErrorAction Stop

        Write-Host "Domain : $($Domain.DNSRoot)"
        Write-Host "Forest : $($Forest.Name)"
        Write-Host ""

        # Domain
        $Results += [PSCustomObject]@{
            Component = 'Domain'
            Status    = 'PASS'
            Details   = $Domain.DNSRoot
        }

        # Forest
        $Results += [PSCustomObject]@{
            Component = 'Forest'
            Status    = 'PASS'
            Details   = $Forest.Name
        }

        # Domain Controllers
        try {
            $DomainControllers = @(
                Get-ADDomainController `
                    -Filter * `
                    -ErrorAction Stop
            )

            $EnabledDCs = @(
                $DomainControllers |
                Where-Object {
                    $_.Enabled -eq $true
                }
            )

            $DisabledDCs = @(
                $DomainControllers |
                Where-Object {
                    $_.Enabled -ne $true
                }
            )

            if ($DisabledDCs.Count -eq 0) {
                $DCStatus = 'PASS'
                $DCDetails = "$($EnabledDCs.Count) domain controller(s)"
            }
            else {
                $DCStatus = 'WARN'
                $DCDetails = "$($EnabledDCs.Count) enabled, $($DisabledDCs.Count) disabled"
            }

            $Results += [PSCustomObject]@{
                Component = 'Domain Controllers'
                Status    = $DCStatus
                Details   = $DCDetails
            }
        }
        catch {
            $DomainControllers = @()

            $Results += [PSCustomObject]@{
                Component = 'Domain Controllers'
                Status    = 'FAIL'
                Details   = $_.Exception.Message
            }
        }

        # Global Catalogs
        try {
            $GlobalCatalogs = @(
                $DomainControllers |
                Where-Object {
                    $_.IsGlobalCatalog -eq $true
                }
            )

            if ($GlobalCatalogs.Count -gt 0) {
                $Results += [PSCustomObject]@{
                    Component = 'Global Catalogs'
                    Status    = 'PASS'
                    Details   = "$($GlobalCatalogs.Count) global catalog(s)"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Component = 'Global Catalogs'
                    Status    = 'FAIL'
                    Details   = 'No global catalog found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Component = 'Global Catalogs'
                Status    = 'FAIL'
                Details   = $_.Exception.Message
            }
        }

        # DNS
        try {
            $DnsRecords = @(
                Resolve-DnsName `
                    -Name "_ldap._tcp.dc._msdcs.$($Domain.DNSRoot)" `
                    -Type SRV `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Type -eq 'SRV'
                }
            )

            $DnsTargets = @(
                $DnsRecords |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.NameTarget)
                } |
                Select-Object -ExpandProperty NameTarget -Unique
            )

            if ($DnsTargets.Count -gt 0) {
                $Results += [PSCustomObject]@{
                    Component = 'AD DNS'
                    Status    = 'PASS'
                    Details   = "$($DnsTargets.Count) DC SRV record(s)"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Component = 'AD DNS'
                    Status    = 'FAIL'
                    Details   = 'No LDAP DC SRV records found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Component = 'AD DNS'
                Status    = 'FAIL'
                Details   = $_.Exception.Message
            }
        }

        # Replication
        if ($DomainControllers.Count -gt 0) {
            $CurrentReplicationFailures = 0
            $RecentReplicationFailures = 0

            foreach ($DC in $DomainControllers) {
                try {
                    $Partners = @(
                        Get-ADReplicationPartnerMetadata `
                            -Target $DC.HostName `
                            -PartnerType Inbound `
                            -Partition * `
                            -ErrorAction Stop
                    )

                    $CurrentFailures = @(
                        $Partners |
                        Where-Object {
                            $_.LastReplicationResult -ne 0 -or
                            $_.ConsecutiveReplicationFailures -gt 0
                        }
                    )

                    $CurrentReplicationFailures += $CurrentFailures.Count
                }
                catch {
                    $CurrentReplicationFailures++
                }

                try {
                    $Failures = @(
                        Get-ADReplicationFailure `
                            -Target $DC.HostName `
                            -ErrorAction Stop
                    )

                    $RecentReplicationFailures += $Failures.Count
                }
                catch {
                    $CurrentReplicationFailures++
                }
            }

            if ($CurrentReplicationFailures -gt 0) {
                $Results += [PSCustomObject]@{
                    Component = 'Replication'
                    Status    = 'FAIL'
                    Details   = "$CurrentReplicationFailures current failure(s), $RecentReplicationFailures recent failure(s)"
                }
            }
            elseif ($RecentReplicationFailures -gt 0) {
                $Results += [PSCustomObject]@{
                    Component = 'Replication'
                    Status    = 'WARN'
                    Details   = "No current failures, $RecentReplicationFailures recent failure(s)"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Component = 'Replication'
                    Status    = 'PASS'
                    Details   = 'No current or recent replication failures detected'
                }
            }
        }
        else {
            $Results += [PSCustomObject]@{
                Component = 'Replication'
                Status    = 'WARN'
                Details   = 'Domain controllers could not be enumerated'
            }
        }

        # SYSVOL / NETLOGON
        if ($DomainControllers.Count -gt 0) {
            $SYSVOLFailures = @()
            $NETLOGONFailures = @()

            foreach ($DC in $DomainControllers) {
                $SYSVOLPath = "\\$($DC.HostName)\SYSVOL"
                $NETLOGONPath = "\\$($DC.HostName)\NETLOGON"

                if (-not (Test-Path $SYSVOLPath -ErrorAction SilentlyContinue)) {
                    $SYSVOLFailures += $DC.HostName
                }

                if (-not (Test-Path $NETLOGONPath -ErrorAction SilentlyContinue)) {
                    $NETLOGONFailures += $DC.HostName
                }
            }

            if ($SYSVOLFailures.Count -eq 0 -and $NETLOGONFailures.Count -eq 0) {
                $Results += [PSCustomObject]@{
                    Component = 'SYSVOL / NETLOGON'
                    Status    = 'PASS'
                    Details   = 'Available on all domain controllers'
                }
            }
            else {
                $Details = @()

                if ($SYSVOLFailures.Count -gt 0) {
                    $Details += "SYSVOL unavailable: $($SYSVOLFailures -join ', ')"
                }

                if ($NETLOGONFailures.Count -gt 0) {
                    $Details += "NETLOGON unavailable: $($NETLOGONFailures -join ', ')"
                }

                $Results += [PSCustomObject]@{
                    Component = 'SYSVOL / NETLOGON'
                    Status    = 'FAIL'
                    Details   = $Details -join '; '
                }
            }
        }

        Write-Host "`nHealth Results" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $Results |
            Format-Table `
                Component,
                Status,
                Details `
                -Wrap `
                -AutoSize

        $Failed = @(
            $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }
        )

        $Warnings = @(
            $Results |
            Where-Object {
                $_.Status -eq 'WARN'
            }
        )

        Write-Host ""

        if ($Failed) {
            Write-Host "AD health problems detected." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "AD health check completed with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "Active Directory health check passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to generate AD health summary." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}