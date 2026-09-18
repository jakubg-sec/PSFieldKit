function Test-ADReplicationDiagnostics {
    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDomain controller name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        Write-Host "`nActive Directory Replication Diagnostics" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host ""

        $Results = @()

        # 1. Replication Summary
        Write-Host "`n[1] Replication Summary" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan

        $Output = & repadmin.exe /replsummary 2>&1
        $ExitCode = $LASTEXITCODE

        if ($Output) {
            $Output | Out-Host
        }

        $Results += [PSCustomObject]@{
            Test   = 'Replication Summary'
            Status = if ($ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        }

        # 2. Replication Partners
        Write-Host "`n[2] Replication Partners" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan

        $Output = & repadmin.exe /showrepl $HostName /errorsonly 2>&1
        $ExitCode = $LASTEXITCODE

        if ($Output) {
            $Output | Out-Host
        }
        else {
            Write-Host "No replication errors reported." -ForegroundColor Green
        }

        $Results += [PSCustomObject]@{
            Test   = 'Replication Partners'
            Status = if ($ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        }

        # 3. Replication Queue
        Write-Host "`n[3] Replication Queue" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        $Output = & repadmin.exe /queue $HostName 2>&1
        $ExitCode = $LASTEXITCODE

        if ($Output) {
            $Output | Out-Host
        }

        $Results += [PSCustomObject]@{
            Test   = 'Replication Queue'
            Status = if ($ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        }

        # 4. DCDIAG Replications
        Write-Host "`n[4] DCDIAG Replications" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan

        $Output = & dcdiag.exe `
            "/s:$HostName" `
            '/test:replications' `
            '/q' 2>&1

        $ExitCode = $LASTEXITCODE

        if ($Output) {
            $Output | Out-Host
        }
        else {
            Write-Host "No replication errors reported by DCDIAG." `
                -ForegroundColor Green
        }

        $Results += [PSCustomObject]@{
            Test   = 'DCDIAG Replications'
            Status = if ($ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
        }

        Write-Host "`nDiagnostic Summary" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $Results |
            Format-Table `
                Test,
                Status `
                -AutoSize

        $Failed = @(
            $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }
        )

        Write-Host ""

        if ($Failed) {
            Write-Host "Replication diagnostics detected problems." `
                -ForegroundColor Red
        }
        else {
            Write-Host "No replication problems were detected." `
                -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to run replication diagnostics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}