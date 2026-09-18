function Reset-ADComputerAccount {

    $Identity = Read-Host "Enter computer name or DNS hostname"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nComputer identity cannot be empty." `
            -ForegroundColor Red

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

            Write-Host "`nComputer account is disabled." `
                -ForegroundColor Yellow

            return
        }

        $Target = if ($Computer.DNSHostName) {
            $Computer.DNSHostName
        }
        else {
            $Computer.Name
        }

        Write-Host "`nWARNING: This operation resets the computer account password" `
            -ForegroundColor Yellow

        Write-Host "and attempts to repair the domain secure channel." `
            -ForegroundColor Yellow

        $Confirmation = Read-Host "`nReset computer account? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nResetting computer account password on $Target..." `
            -ForegroundColor Yellow

        Invoke-Command `
            -ComputerName $Target `
            -ScriptBlock {
                Reset-ComputerMachinePassword -ErrorAction Stop
            } `
            -ErrorAction Stop | Out-Null

        Write-Host "`nComputer account password reset successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to reset computer account." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}