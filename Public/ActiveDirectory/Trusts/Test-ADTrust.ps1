function Test-ADTrust {
    $Identity = Read-Host "Enter trusted domain name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nTrusted domain name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Trust = Get-ADTrust `
            -Identity $Identity `
            -Properties * `
            -ErrorAction Stop

        Write-Host "`nAD Trust Verification" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan
        Write-Host "Source Domain : $($Trust.Source)"
        Write-Host "Target Domain : $($Trust.Target)"
        Write-Host "Direction     : $($Trust.Direction)"
        Write-Host "Trust Type    : $($Trust.TrustType)"
        Write-Host ""

        $Confirm = Read-Host "Verify this trust? (Y/N)"

        if ($Confirm -notmatch '^[Yy]$') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        $NetDomPath = Get-Command netdom.exe -ErrorAction SilentlyContinue

        if (-not $NetDomPath) {
            Write-Host "`nnetdom.exe was not found." -ForegroundColor Red
            Write-Host "Install Active Directory Domain Services tools / RSAT." -ForegroundColor Yellow
            return
        }

        Write-Host "`nVerifying trust..." -ForegroundColor Yellow
        Write-Host ""

        $Output = & $NetDomPath.Source `
            trust `
            $Trust.Source `
            "/domain:$($Trust.Target)" `
            '/verify' `
            '/verbose' 2>&1

        if ($Output) {
            $Output | Out-Host
        }

        $ExitCode = $LASTEXITCODE

        Write-Host ""

        if ($ExitCode -eq 0) {
            Write-Host "Trust verification completed successfully." -ForegroundColor Green

            [PSCustomObject]@{
                Source = $Trust.Source
                Target = $Trust.Target
                Status = 'PASS'
                ExitCode = $ExitCode
            } | Format-List
        }
        else {
            Write-Host "Trust verification failed." -ForegroundColor Red

            [PSCustomObject]@{
                Source = $Trust.Source
                Target = $Trust.Target
                Status = 'FAIL'
                ExitCode = $ExitCode
            } | Format-List
        }
    }
    catch {
        Write-Host "`nFailed to test trust." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}