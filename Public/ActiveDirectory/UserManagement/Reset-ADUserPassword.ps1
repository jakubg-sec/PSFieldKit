function Reset-ADUserPassword {

    $Identity = Read-Host "Enter username or UPN"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nUsername cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties Enabled, LockedOut, UserPrincipalName `
            -ErrorAction Stop

        Write-Host "`nUser Information" -ForegroundColor Cyan
        Write-Host "----------------"
        Write-Host "Name      : $($User.Name)"
        Write-Host "Login     : $($User.SamAccountName)"
        Write-Host "UPN       : $($User.UserPrincipalName)"
        Write-Host "Enabled   : $($User.Enabled)"
        Write-Host "LockedOut : $($User.LockedOut)"

        if (-not $User.Enabled) {

            Write-Host "`nUser account is disabled." -ForegroundColor Yellow

            return
        }

        $Password = Read-Host `
            "Enter new temporary password" `
            -AsSecureString

        $PasswordConfirmation = Read-Host `
            "Confirm new temporary password" `
            -AsSecureString

        $PasswordText = [System.Net.NetworkCredential]::new(
            '',
            $Password
        ).Password

        $PasswordConfirmationText = [System.Net.NetworkCredential]::new(
            '',
            $PasswordConfirmation
        ).Password

        if ($PasswordText -cne $PasswordConfirmationText) {

            Write-Host "`nPasswords do not match." `
                -ForegroundColor Red

            $PasswordText = $null
            $PasswordConfirmationText = $null

            return
        }

        $PasswordText = $null
        $PasswordConfirmationText = $null

        $Confirmation = Read-Host "`nReset password for this user? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." -ForegroundColor Yellow

            return
        }

        Set-ADAccountPassword `
            -Identity $User `
            -Reset `
            -NewPassword $Password `
            -ErrorAction Stop

        Set-ADUser `
            -Identity $User `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Write-Host "`nPassword reset successfully." `
            -ForegroundColor Green

        Write-Host "User must change the password at next logon." `
            -ForegroundColor Yellow
    }

    catch {

        Write-Host "`nFailed to reset user password." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}