function New-PSFieldKitExchangeMailbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                 Create Mailbox               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $Name = Read-Host "Name"

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host ""
        Write-Host "Name cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $UserPrincipalName = Read-Host "User Principal Name"

    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
        Write-Host ""
        Write-Host "User Principal Name cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($UserPrincipalName -notmatch '^[^@\s]+@[^@\s]+$') {
        Write-Host ""
        Write-Host "Invalid User Principal Name format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $FirstName = Read-Host "First Name"
    $LastName = Read-Host "Last Name"
    $DisplayName = Read-Host "Display Name"

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Name
    }

    $Alias = Read-Host "Alias"

    if ([string]::IsNullOrWhiteSpace($Alias)) {
        $Alias = ($UserPrincipalName -split "@")[0]
    }

    $OrganizationalUnit = Read-Host "Organizational Unit (optional)"
    $Database = Read-Host "Mailbox Database (optional)"

    Write-Host ""
    Write-Host "Enter initial password." -ForegroundColor Cyan

    $Password = Read-Host "Password" -AsSecureString

    if ($null -eq $Password) {
        Write-Host ""
        Write-Host "Password cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    $ResetPasswordInput = Read-Host "Require password change on next logon? (Y/N)"

    $ResetPasswordOnNextLogon = $false

    if ($ResetPasswordInput -match '^[Yy]$') {
        $ResetPasswordOnNextLogon = $true
    }

    Write-Host ""
    Write-Host "Mailbox configuration:" -ForegroundColor Cyan
    Write-Host "  Name                   : $Name"
    Write-Host "  UPN                    : $UserPrincipalName"
    Write-Host "  First Name             : $FirstName"
    Write-Host "  Last Name              : $LastName"
    Write-Host "  Display Name           : $DisplayName"
    Write-Host "  Alias                  : $Alias"
    Write-Host "  Organizational Unit    : $(if ([string]::IsNullOrWhiteSpace($OrganizationalUnit)) { "Default" } else { $OrganizationalUnit })"
    Write-Host "  Mailbox Database       : $(if ([string]::IsNullOrWhiteSpace($Database)) { "Automatic" } else { $Database })"
    Write-Host "  Password Reset Required: $ResetPasswordOnNextLogon"

    Write-Host ""
    $Confirmation = Read-Host "Create mailbox? (Y/N)"

    if ($Confirmation -notmatch '^[Yy]$') {
        Write-Host ""
        Write-Host "Mailbox creation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        $MailboxParameters = @{
            Name                     = $Name
            UserPrincipalName        = $UserPrincipalName
            Password                 = $Password
            Alias                    = $Alias
            ResetPasswordOnNextLogon = $ResetPasswordOnNextLogon
            ErrorAction              = "Stop"
        }

        if (-not [string]::IsNullOrWhiteSpace($FirstName)) {
            $MailboxParameters["FirstName"] = $FirstName
        }

        if (-not [string]::IsNullOrWhiteSpace($LastName)) {
            $MailboxParameters["LastName"] = $LastName
        }

        if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
            $MailboxParameters["DisplayName"] = $DisplayName
        }

        if (-not [string]::IsNullOrWhiteSpace($OrganizationalUnit)) {
            $MailboxParameters["OrganizationalUnit"] = $OrganizationalUnit
        }

        if (-not [string]::IsNullOrWhiteSpace($Database)) {
            $MailboxParameters["Database"] = $Database
        }

        Write-Host ""
        Write-Host "Creating mailbox..." -ForegroundColor Yellow

        $Mailbox = New-Mailbox @MailboxParameters

        Write-Host ""
        Write-Host "Mailbox created successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Name          : $($Mailbox.DisplayName)" -ForegroundColor White
        Write-Host "Alias         : $($Mailbox.Alias)" -ForegroundColor White
        Write-Host "Primary SMTP  : $($Mailbox.PrimarySmtpAddress)" -ForegroundColor White
        Write-Host "Database      : $($Mailbox.Database)" -ForegroundColor White
    }
    catch {
        Write-Host ""
        Write-Host "Failed to create mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}