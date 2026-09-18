function Enable-ADUserAccount {

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

        if ($User.Enabled) {

            Write-Host "`nUser is already enabled." -ForegroundColor Yellow
            return
        }

        $Confirmation = Read-Host "`nEnable this user? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Enable-ADAccount `
            -Identity $User `
            -ErrorAction Stop

        Write-Host "`nUser '$($User.SamAccountName)' has been enabled successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to enable user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}