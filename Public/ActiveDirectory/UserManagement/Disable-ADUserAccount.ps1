function Disable-ADUserAccount {

    $Identity = Read-Host "Enter username or UPN"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nUsername cannot be empty." -ForegroundColor Red
        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties Enabled, UserPrincipalName `
            -ErrorAction Stop

        Write-Host "`nUser Information" -ForegroundColor Cyan
        Write-Host "----------------"
        Write-Host "Name    : $($User.Name)"
        Write-Host "Login   : $($User.SamAccountName)"
        Write-Host "UPN     : $($User.UserPrincipalName)"
        Write-Host "Enabled : $($User.Enabled)"

        if (-not $User.Enabled) {

            Write-Host "`nUser is already disabled." -ForegroundColor Yellow
            return
        }

        $Confirmation = Read-Host "`nDisable this user? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Disable-ADAccount `
            -Identity $User `
            -ErrorAction Stop

        Write-Host "`nUser '$($User.SamAccountName)' has been disabled successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to disable user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}