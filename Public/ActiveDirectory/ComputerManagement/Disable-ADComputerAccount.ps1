function Disable-ADComputerAccount {

    $Identity = Read-Host "Enter computer name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nComputer identity cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $Computer = Get-ADComputer `
            -Identity $Identity `
            -Properties Enabled, DNSHostName, OperatingSystem `
            -ErrorAction Stop

        Write-Host "`nComputer Information" -ForegroundColor Cyan
        Write-Host "--------------------"
        Write-Host "Name      : $($Computer.Name)"
        Write-Host "DNS       : $($Computer.DNSHostName)"
        Write-Host "OS        : $($Computer.OperatingSystem)"
        Write-Host "Enabled   : $($Computer.Enabled)"

        if (-not $Computer.Enabled) {

            Write-Host "`nComputer account is already disabled." `
                -ForegroundColor Yellow

            return
        }

        $Confirmation = Read-Host "`nDisable this computer account? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow

            return
        }

        Disable-ADAccount `
            -Identity $Computer `
            -ErrorAction Stop

        Write-Host "`nComputer account '$($Computer.Name)' has been disabled successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to disable computer account." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}