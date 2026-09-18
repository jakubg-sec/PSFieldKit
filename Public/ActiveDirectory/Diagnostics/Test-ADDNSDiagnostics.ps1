function Test-ADDNSDiagnostics {
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        $Forest = Get-ADForest -ErrorAction Stop
        $Results = @()

        Write-Host "`nActive Directory DNS Diagnostics" -ForegroundColor Cyan
        Write-Host "--------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain : $($Domain.DNSRoot)"
        Write-Host "Forest : $($Forest.Name)"
        Write-Host ""

        # 1. DNS server configuration
        try {
            $DnsServers = @(
                Get-DnsClientServerAddress `
                    -AddressFamily IPv4 `
                    -ErrorAction Stop |
                Where-Object {
                    $_.ServerAddresses
                } |
                ForEach-Object {
                    $_.ServerAddresses
                } |
                Select-Object -Unique
            )

            if ($DnsServers.Count -gt 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'DNS Server Configuration'
                    Status  = 'PASS'
                    Details = $DnsServers -join ', '
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'DNS Server Configuration'
                    Status  = 'FAIL'
                    Details = 'No IPv4 DNS servers configured'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'DNS Server Configuration'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 2. Domain resolution
        try {
            $DomainRecords = Resolve-DnsName `
                -Name $Domain.DNSRoot `
                -ErrorAction Stop

            $DomainAddresses = @(
                $DomainRecords |
                Where-Object {
                    $_.Type -eq 'A' -or $_.Type -eq 'AAAA'
                } |
                Select-Object -ExpandProperty IPAddress
            )

            $Results += [PSCustomObject]@{
                Test    = 'Domain Resolution'
                Status  = if ($DomainAddresses.Count -gt 0) { 'PASS' } else { 'WARN' }
                Details = if ($DomainAddresses.Count -gt 0) {
                    $DomainAddresses -join ', '
                }
                else {
                    'Domain resolved without A/AAAA records'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Domain Resolution'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 3. LDAP SRV records
        try {
            $LdapSrv = @(
                Resolve-DnsName `
                    -Name "_ldap._tcp.dc._msdcs.$($Domain.DNSRoot)" `
                    -Type SRV `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Type -eq 'SRV'
                }
            )

            $LdapTargets = @(
                $LdapSrv |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.NameTarget)
                } |
                Select-Object -ExpandProperty NameTarget -Unique
            )

            $Results += [PSCustomObject]@{
                Test    = 'LDAP SRV Records'
                Status  = if ($LdapTargets.Count -gt 0) { 'PASS' } else { 'FAIL' }
                Details = if ($LdapTargets.Count -gt 0) {
                    $LdapTargets -join ', '
                }
                else {
                    'No LDAP SRV records found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'LDAP SRV Records'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 4. Kerberos SRV records
        try {
            $KerberosSrv = @(
                Resolve-DnsName `
                    -Name "_kerberos._tcp.$($Domain.DNSRoot)" `
                    -Type SRV `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Type -eq 'SRV'
                }
            )

            $KerberosTargets = @(
                $KerberosSrv |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.NameTarget)
                } |
                Select-Object -ExpandProperty NameTarget -Unique
            )

            $Results += [PSCustomObject]@{
                Test    = 'Kerberos SRV Records'
                Status  = if ($KerberosTargets.Count -gt 0) { 'PASS' } else { 'FAIL' }
                Details = if ($KerberosTargets.Count -gt 0) {
                    $KerberosTargets -join ', '
                }
                else {
                    'No Kerberos SRV records found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Kerberos SRV Records'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 5. DC Locator
        $DomainControllers = @()

        try {
            $DomainControllers = @(
                Get-ADDomainController `
                    -Filter * `
                    -ErrorAction Stop
            )

            if ($DomainControllers.Count -gt 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Enumeration'
                    Status  = 'PASS'
                    Details = "$($DomainControllers.Count) domain controller(s) found"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Enumeration'
                    Status  = 'FAIL'
                    Details = 'No domain controllers found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'DC Enumeration'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 6. DC hostname resolution
        if ($DomainControllers.Count -gt 0) {
            $FailedDCResolution = @()

            foreach ($DC in $DomainControllers) {
                try {
                    Resolve-DnsName `
                        -Name $DC.HostName `
                        -ErrorAction Stop |
                        Out-Null
                }
                catch {
                    $FailedDCResolution += $DC.HostName
                }
            }

            if ($FailedDCResolution.Count -eq 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Hostname Resolution'
                    Status  = 'PASS'
                    Details = 'All domain controllers resolve correctly'
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Hostname Resolution'
                    Status  = 'FAIL'
                    Details = "Failed: $($FailedDCResolution -join ', ')"
                }
            }
        }

        # 7. DNS reverse lookup for DCs
        if ($DomainControllers.Count -gt 0) {
            $ReverseLookupFailures = @()

            foreach ($DC in $DomainControllers) {
                if ([string]::IsNullOrWhiteSpace($DC.IPv4Address)) {
                    continue
                }

                try {
                    $ReverseName = Resolve-DnsName `
                        -Name $DC.IPv4Address `
                        -Type PTR `
                        -ErrorAction Stop

                    if (-not $ReverseName) {
                        $ReverseLookupFailures += $DC.HostName
                    }
                }
                catch {
                    $ReverseLookupFailures += $DC.HostName
                }
            }

            if ($ReverseLookupFailures.Count -eq 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Reverse DNS'
                    Status  = 'PASS'
                    Details = 'Reverse DNS succeeded for all tested DCs'
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'DC Reverse DNS'
                    Status  = 'WARN'
                    Details = "Failed: $($ReverseLookupFailures -join ', ')"
                }
            }
        }

        Write-Host "`nDNS Diagnostic Results" -ForegroundColor Cyan
        Write-Host "----------------------" -ForegroundColor DarkCyan

        $Results |
            Format-Table `
                Test,
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
            Write-Host "AD DNS diagnostics detected problems." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "AD DNS diagnostics completed with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "All AD DNS diagnostics passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to run AD DNS diagnostics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}