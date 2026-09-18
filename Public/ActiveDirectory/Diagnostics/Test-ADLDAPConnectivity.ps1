function Test-ADLDAPConnectivity {
    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDomain controller name cannot be empty." -ForegroundColor Red
        return
    }

    function Test-TCPPort {
        param(
            [Parameter(Mandatory)]
            [string]$ComputerName,
            [Parameter(Mandatory)]
            [int]$Port,
            [int]$Timeout = 1500
        )

        $Client = $null

        try {
            $Client = New-Object System.Net.Sockets.TcpClient
            $AsyncResult = $Client.BeginConnect(
                $ComputerName,
                $Port,
                $null,
                $null
            )

            $Connected = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout)

            if ($Connected -and $Client.Connected) {
                $Client.EndConnect($AsyncResult)
                return $true
            }

            return $false
        }
        catch {
            return $false
        }
        finally {
            if ($Client) {
                $Client.Close()
            }
        }
    }

    try {
        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        Write-Host "`nActive Directory LDAP Connectivity" -ForegroundColor Cyan
        Write-Host "----------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host "IPv4              : $($DC.IPv4Address)"
        Write-Host ""

        $Results = @()

        # 1. LDAP TCP 389
        $LDAPPort = Test-TCPPort `
            -ComputerName $HostName `
            -Port 389

        $Results += [PSCustomObject]@{
            Test    = 'LDAP TCP 389'
            Status  = if ($LDAPPort) { 'PASS' } else { 'FAIL' }
            Details = if ($LDAPPort) {
                'LDAP port is reachable'
            }
            else {
                'LDAP port is not reachable'
            }
        }

        # 2. LDAP RootDSE
        try {
            $RootDSE = Get-ADRootDSE `
                -Server $HostName `
                -ErrorAction Stop

            $Results += [PSCustomObject]@{
                Test    = 'LDAP RootDSE'
                Status  = 'PASS'
                Details = "Default naming context: $($RootDSE.defaultNamingContext)"
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'LDAP RootDSE'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 3. LDAP naming contexts
        if ($RootDSE) {
            $Results += [PSCustomObject]@{
                Test    = 'LDAP Naming Contexts'
                Status  = 'PASS'
                Details = @(
                    "Default : $($RootDSE.defaultNamingContext)"
                    "Config  : $($RootDSE.configurationNamingContext)"
                    "Schema  : $($RootDSE.schemaNamingContext)"
                ) -join ' | '
            }
        }

        # 4. LDAPS TCP 636
        $LDAPSPort = Test-TCPPort `
            -ComputerName $HostName `
            -Port 636

        $Results += [PSCustomObject]@{
            Test    = 'LDAPS TCP 636'
            Status  = if ($LDAPSPort) { 'PASS' } else { 'WARN' }
            Details = if ($LDAPSPort) {
                'LDAPS port is reachable'
            }
            else {
                'LDAPS port is not reachable or LDAPS is not enabled'
            }
        }

        Write-Host "`nLDAP Connectivity Results" -ForegroundColor Cyan
        Write-Host "-------------------------" -ForegroundColor DarkCyan

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
            Write-Host "LDAP connectivity problems detected." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "LDAP connectivity is working, with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "LDAP connectivity test passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to test LDAP connectivity." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}