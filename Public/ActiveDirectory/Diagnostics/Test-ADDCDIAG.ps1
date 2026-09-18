function Test-ADDCDIAG {
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

        $DCDiag = Get-Command dcdiag.exe -ErrorAction SilentlyContinue

        if (-not $DCDiag) {
            Write-Host "`ndcdiag.exe was not found." -ForegroundColor Red
            Write-Host "Install Active Directory Domain Services tools / RSAT." -ForegroundColor Yellow
            return
        }

        Write-Host "`nActive Directory Domain Controller Diagnostics" -ForegroundColor Cyan
        Write-Host "----------------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host "Mode              : Comprehensive"
        Write-Host ""

        $Confirm = Read-Host "Run DCDIAG? (Y/N)"

        if ($Confirm -notmatch '^[Yy]$') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Write-Host "`nRunning DCDIAG..." -ForegroundColor Yellow
        Write-Host ""

        $Output = & $DCDiag.Source `
            "/s:$HostName" `
            '/c' 2>&1

        $ExitCode = $LASTEXITCODE

        if ($Output) {
            $Output | Out-Host
        }

        Write-Host ""

        if ($ExitCode -eq 0) {
            Write-Host "DCDIAG completed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "DCDIAG completed with errors." -ForegroundColor Red
            Write-Host "Exit code: $ExitCode" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nFailed to run DCDIAG." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}