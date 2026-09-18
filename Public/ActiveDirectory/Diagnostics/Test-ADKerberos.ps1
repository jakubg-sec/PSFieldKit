function Test-ADKerberos {
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

        $Domain = Get-ADDomain -ErrorAction Stop

        $HostName = $DC.HostName
        $DomainName = $Domain.DNSRoot

        Write-Host "`nActive Directory Kerberos Diagnostics" -ForegroundColor Cyan
        Write-Host "-------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host "Domain            : $DomainName"
        Write-Host "KDC               : $HostName"
        Write-Host ""

        $Results = @()

        # 1. Kerberos TCP 88
        $KerberosPort = Test-TCPPort `
            -ComputerName $HostName `
            -Port 88

        $Results += [PSCustomObject]@{
            Test    = 'Kerberos TCP 88'
            Status  = if ($KerberosPort) { 'PASS' } else { 'FAIL' }
            Details = if ($KerberosPort) {
                'Kerberos port is reachable'
            }
            else {
                'Kerberos port is not reachable'
            }
        }

        # 2. Kerberos UDP 88
        $Results += [PSCustomObject]@{
            Test    = 'Kerberos UDP 88'
            Status  = 'INFO'
            Details = 'UDP transport is not verified by packet send; Kerberos ticket test is used below'
        }

        # 3. KDC service
        try {
            $KDCService = Get-CimInstance `
                -ClassName Win32_Service `
                -ComputerName $HostName `
                -Filter "Name = 'KDC'" `
                -ErrorAction Stop

            if ($KDCService.State -eq 'Running') {
                $Results += [PSCustomObject]@{
                    Test    = 'KDC Service'
                    Status  = 'PASS'
                    Details = "KDC service is $($KDCService.State)"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'KDC Service'
                    Status  = 'FAIL'
                    Details = "KDC service is $($KDCService.State)"
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'KDC Service'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 4. Kerberos SRV
        try {
            $KerberosSRV = @(
                Resolve-DnsName `
                    -Name "_kerberos._tcp.$DomainName" `
                    -Type SRV `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Type -eq 'SRV'
                }
            )

            $KDCs = @(
                $KerberosSRV |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.NameTarget)
                } |
                Select-Object -ExpandProperty NameTarget -Unique
            )

            $Results += [PSCustomObject]@{
                Test    = 'Kerberos SRV'
                Status  = if ($KDCs.Count -gt 0) { 'PASS' } else { 'FAIL' }
                Details = if ($KDCs.Count -gt 0) {
                    $KDCs -join ', '
                }
                else {
                    'No Kerberos SRV records found'
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Kerberos SRV'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 5. Kerberos ticket
        $Klist = Get-Command klist.exe -ErrorAction SilentlyContinue

        if (-not $Klist) {
            $Results += [PSCustomObject]@{
                Test    = 'Kerberos Ticket'
                Status  = 'WARN'
                Details = 'klist.exe not found'
            }
        }
        else {
            Write-Host "`nRequesting Kerberos TGT..." -ForegroundColor Yellow

            $SPN = "krbtgt/$DomainName"

            $KlistOutput = & $Klist.Source `
                get `
                $SPN 2>&1

            $KlistExitCode = $LASTEXITCODE

            if ($KlistExitCode -eq 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'Kerberos Ticket'
                    Status  = 'PASS'
                    Details = "TGT request for $SPN succeeded"
                }
            }
            else {
                $Details = ($KlistOutput | Out-String).Trim()

                if ([string]::IsNullOrWhiteSpace($Details)) {
                    $Details = "klist exited with code $KlistExitCode"
                }

                $Results += [PSCustomObject]@{
                    Test    = 'Kerberos Ticket'
                    Status  = 'FAIL'
                    Details = $Details
                }
            }
        }

        Write-Host "`nKerberos Diagnostic Results" -ForegroundColor Cyan
        Write-Host "---------------------------" -ForegroundColor DarkCyan

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
            Write-Host "Kerberos problems detected." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "Kerberos test completed with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "Kerberos test passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to run Kerberos diagnostics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}