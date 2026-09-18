function New-ADUserAccount {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        # Default container for user accounts
        $DefaultOU = $Domain.UsersContainer

        Write-Host "`nCreate User" -ForegroundColor Cyan
        Write-Host "-----------" -ForegroundColor DarkCyan

        # First name
        $GivenName = Read-Host "First name"

        # Last name
        $Surname = Read-Host "Last name"

        if ([string]::IsNullOrWhiteSpace($GivenName) -or
            [string]::IsNullOrWhiteSpace($Surname)) {

            Write-Host "`nFirst name and last name are required." `
                -ForegroundColor Red

            return
        }

        # Display name
        $DisplayName = Read-Host "Display name [$GivenName $Surname]"

        if ([string]::IsNullOrWhiteSpace($DisplayName)) {
            $DisplayName = "$GivenName $Surname"
        }

        # Login
        $SamAccountName = Read-Host "Login"

        if ([string]::IsNullOrWhiteSpace($SamAccountName)) {

            Write-Host "`nLogin cannot be empty." `
                -ForegroundColor Red

            return
        }

        # UPN
        $UserPrincipalName = "$SamAccountName@$($Domain.DNSRoot)"

        # Password
        $Password = Read-Host `
            "Temporary password" `
            -AsSecureString

        $PasswordConfirmation = Read-Host `
            "Confirm temporary password" `
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

            return
        }

        # Clear plaintext password variables
        $PasswordText = $null
        $PasswordConfirmationText = $null

        # Account expiration
        Write-Host "`nAccount expiration:" -ForegroundColor Cyan
        Write-Host "[1] Never"
        Write-Host "[2] Set expiration date"

        $ExpirationChoice = Read-Host "Select option"

        $AccountExpirationDate = $null

        switch ($ExpirationChoice) {

            '1' {
                $AccountExpirationDate = $null
            }

            '2' {

                $ExpirationInput = Read-Host `
                    "Expiration date (yyyy-MM-dd)"

                try {

                    $AccountExpirationDate = [datetime]::ParseExact(
                        $ExpirationInput,
                        'yyyy-MM-dd',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }
                catch {

                    Write-Host "`nInvalid date format." `
                        -ForegroundColor Red

                    return
                }
            }

            default {

                Write-Host "`nInvalid option." `
                    -ForegroundColor Red

                return
            }
        }

        # OU / Container
        $Path = Read-Host "OU [$DefaultOU]"

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = $DefaultOU
        }

        # Validate OU / Container
        try {

            Get-ADObject `
                -Identity $Path `
                -ErrorAction Stop |
                Out-Null
        }
        catch {

            Write-Host "`nOU or container not found: $Path" `
                -ForegroundColor Red

            return
        }

        # Check existing account
        $ExistingUser = Get-ADUser `
            -Filter "SamAccountName -eq '$SamAccountName'" `
            -ErrorAction SilentlyContinue

        if ($ExistingUser) {

            Write-Host "`nUser '$SamAccountName' already exists." `
                -ForegroundColor Red

            return
        }

        # Summary
        Write-Host "`n----------------------------------------------"
        Write-Host "User Summary" -ForegroundColor Cyan
        Write-Host "----------------------------------------------"

        Write-Host "Name        : $DisplayName"
        Write-Host "Login       : $SamAccountName"
        Write-Host "UPN         : $UserPrincipalName"

        if ($null -eq $AccountExpirationDate) {
            Write-Host "Expiration  : Never"
        }
        else {
            Write-Host "Expiration  : $($AccountExpirationDate.ToString('yyyy-MM-dd'))"
        }

        Write-Host "OU          : $Path"
        Write-Host "Password    : Temporary / change at first logon"
        Write-Host "Status      : Enabled"

        Write-Host "----------------------------------------------"

        $Confirmation = Read-Host "Create user? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        # Create user
        $Parameters = @{
            Name                  = $DisplayName
            GivenName             = $GivenName
            Surname               = $Surname
            DisplayName           = $DisplayName
            SamAccountName        = $SamAccountName
            UserPrincipalName     = $UserPrincipalName
            AccountPassword       = $Password
            Path                  = $Path
            Enabled               = $true
            ChangePasswordAtLogon = $true
        }

        if ($null -ne $AccountExpirationDate) {
            $Parameters.AccountExpirationDate = $AccountExpirationDate
        }

        New-ADUser @Parameters -ErrorAction Stop

        Write-Host "`nUser '$DisplayName' created successfully." `
            -ForegroundColor Green

        Write-Host "UPN: $UserPrincipalName" `
            -ForegroundColor Cyan

        Write-Host "The user must change the password at first logon." `
            -ForegroundColor Yellow
    }
    catch {

        Write-Host "`nFailed to create user." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}