function Unlock-ADUserAccount {

    $Identity = Read-Host "Enter username or UPN"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nUsername cannot be empty." -ForegroundColor Red
        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties LockedOut, UserPrincipalName `
            -ErrorAction Stop

        Write-Host "`nUser Information" -ForegroundColor Cyan
        Write-Host "----------------"
        Write-Host "Name      : $($User.Name)"
        Write-Host "Login     : $($User.SamAccountName)"
        Write-Host "UPN       : $($User.UserPrincipalName)"
        Write-Host "LockedOut : $($User.LockedOut)"

        if (-not $User.LockedOut) {

            Write-Host "`nUser is not locked out." -ForegroundColor Yellow
            return
        }

        $Confirmation = Read-Host "`nUnlock this user? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Unlock-ADAccount `
            -Identity $User `
            -ErrorAction Stop

        Write-Host "`nUser '$($User.SamAccountName)' has been unlocked successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to unlock user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}