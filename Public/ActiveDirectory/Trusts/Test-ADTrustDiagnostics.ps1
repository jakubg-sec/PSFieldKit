function Test-ADTrustDiagnostics {
    $Identity = Read-Host "Enter trusted domain name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nTrusted domain name cannot be empty." -ForegroundColor Red
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
        $Trust = Get-ADTrust `
            -Identity $Identity `
            -Properties * `
            -ErrorAction Stop

        $TargetDomain = $Trust.Target

        if ([string]::IsNullOrWhiteSpace($TargetDomain)) {
            $TargetDomain = $Identity
        }

        Write-Host "`nAD Trust Diagnostics" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Source Domain : $($Trust.Source)"
        Write-Host "Target Domain : $TargetDomain"
        Write-Host "Direction     : $($Trust.Direction)"
        Write-Host "Trust Type    : $($Trust.TrustType)"
        Write-Host ""

        $Results = @()

        # 1. DNS - LDAP SRV
        try {
            $LDAPSRV = Resolve-DnsName `
                -Name "_ldap._tcp.dc._msdcs.$TargetDomain" `
                -Type SRV `
                -ErrorAction Stop

            $LDAPTargets = @(
                $LDAPSRV |
                Select-Object -ExpandProperty NameTarget
            )

            $Results += [PSCustomObject]@{
                Test    = 'DNS LDAP SRV'
                Status  = 'PASS'
                Details = ($LDAPTargets -join ', ')
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'DNS LDAP SRV'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 2. DNS - Kerberos SRV
        try {
            $KerberosSRV = Resolve-DnsName `
                -Name "_kerberos._tcp.$TargetDomain" `
                -Type SRV `
                -ErrorAction Stop

            $KerberosTargets = @(
                $KerberosSRV |
                Select-Object -ExpandProperty NameTarget
            )

            $Results += [PSCustomObject]@{
                Test    = 'DNS Kerberos SRV'
                Status  = 'PASS'
                Details = ($KerberosTargets -join ', ')
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'DNS Kerberos SRV'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 3. Domain Controller Discovery
        $TargetDC = $null

        try {
            $TargetDC = Get-ADDomainController `
                -Discover `
                -DomainName $TargetDomain `
                -ErrorAction Stop

            $Results += [PSCustomObject]@{
                Test    = 'DC Discovery'
                Status  = 'PASS'
                Details = $TargetDC.HostName
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'DC Discovery'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        if ($TargetDC) {
            # 4. LDAP
            $LDAP = Test-TCPPort `
                -ComputerName $TargetDC.HostName `
                -Port 389

            $Results += [PSCustomObject]@{
                Test    = 'LDAP (389)'
                Status  = if ($LDAP) { 'PASS' } else { 'FAIL' }
                Details = $TargetDC.HostName
            }

            # 5. Kerberos
            $Kerberos = Test-TCPPort `
                -ComputerName $TargetDC.HostName `
                -Port 88

            $Results += [PSCustomObject]@{
                Test    = 'Kerberos (88)'
                Status  = if ($Kerberos) { 'PASS' } else { 'FAIL' }
                Details = $TargetDC.HostName
            }

            # 6. SMB
            $SMB = Test-TCPPort `
                -ComputerName $TargetDC.HostName `
                -Port 445

            $Results += [PSCustomObject]@{
                Test    = 'SMB (445)'
                Status  = if ($SMB) { 'PASS' } else { 'FAIL' }
                Details = $TargetDC.HostName
            }
        }

        # 7. Trust verification
        $NetDom = Get-Command netdom.exe -ErrorAction SilentlyContinue

        if (-not $NetDom) {
            $Results += [PSCustomObject]@{
                Test    = 'Trust Verification'
                Status  = 'WARN'
                Details = 'netdom.exe not found'
            }
        }
        else {
            Write-Host "`nVerifying trust relationship..." -ForegroundColor Yellow

            $NetDomOutput = & $NetDom.Source `
                trust `
                $Trust.Source `
                "/domain:$TargetDomain" `
                '/verify' `
                '/verbose' 2>&1

            $NetDomExitCode = $LASTEXITCODE

            if ($NetDomExitCode -eq 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'Trust Verification'
                    Status  = 'PASS'
                    Details = 'netdom trust verification succeeded'
                }
            }
            else {
                $Details = ($NetDomOutput | Out-String).Trim()

                if ([string]::IsNullOrWhiteSpace($Details)) {
                    $Details = "netdom exited with code $NetDomExitCode"
                }

                $Results += [PSCustomObject]@{
                    Test    = 'Trust Verification'
                    Status  = 'FAIL'
                    Details = $Details
                }
            }
        }

        Write-Host "`nDiagnostic Results" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

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
            Write-Host "Trust diagnostics detected problems." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "Trust diagnostics completed with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "All trust diagnostics passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to run trust diagnostics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}