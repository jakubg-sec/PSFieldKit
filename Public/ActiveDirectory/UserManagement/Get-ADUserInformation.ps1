function Get-ADUserInformation {

    $Identity = Read-Host "Enter username, UPN or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nIdentity cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $User = Get-ADUser `
            -Identity $Identity `
            -Properties `
                UserPrincipalName,
                Enabled,
                LockedOut,
                PasswordExpired,
                PasswordNeverExpires,
                PasswordLastSet,
                LastLogonDate,
                AccountExpirationDate,
                CannotChangePassword,
                BadLogonCount,
                Created,
                Modified `
            -ErrorAction Stop

        $AccountExpiration = if ($null -eq $User.AccountExpirationDate) {
            'Never'
        }
        else {
            $User.AccountExpirationDate
        }

        [PSCustomObject]@{
            Name                 = $User.Name
            SamAccountName       = $User.SamAccountName
            UserPrincipalName    = $User.UserPrincipalName
            Enabled              = $User.Enabled
            LockedOut            = $User.LockedOut
            PasswordExpired      = $User.PasswordExpired
            PasswordNeverExpires = $User.PasswordNeverExpires
            PasswordLastSet      = $User.PasswordLastSet
            LastLogonDate        = $User.LastLogonDate
            AccountExpiration    = $AccountExpiration
            CannotChangePassword = $User.CannotChangePassword
            BadLogonCount        = $User.BadLogonCount
            Created              = $User.Created
            Modified             = $User.Modified
            DistinguishedName    = $User.DistinguishedName
        } |
        Format-List
    }

    catch {

        Write-Host "`nFailed to retrieve user information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}