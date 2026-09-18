function Remove-ADComputerAccount {

    $Identity = Read-Host "Enter computer name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nComputer identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Computer = Get-ADComputer `
            -Identity $Identity `
            -Properties `
                Enabled,
                DNSHostName,
                OperatingSystem,
                DistinguishedName `
            -ErrorAction Stop

        Write-Host "`nComputer Information" -ForegroundColor Cyan
        Write-Host "--------------------"
        Write-Host "Name        : $($Computer.Name)"
        Write-Host "DNS         : $($Computer.DNSHostName)"
        Write-Host "OS          : $($Computer.OperatingSystem)"
        Write-Host "Enabled     : $($Computer.Enabled)"
        Write-Host "DistinguishedName : $($Computer.DistinguishedName)"

        Write-Host "`nWARNING: This action will permanently remove the AD computer account." `
            -ForegroundColor Red

        $Confirmation = Read-Host "Type DELETE to confirm"

        if ($Confirmation -cne 'DELETE') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        Remove-ADComputer `
            -Identity $Computer `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nComputer '$($Computer.Name)' has been removed successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to remove computer account." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}