function New-PSFieldKitExchangeSharedMailbox {
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

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Create Shared Mailbox             |" -ForegroundColor Cyan
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

    $DisplayName = Read-Host "Display Name"

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = $Name
    }

    $UserPrincipalName = Read-Host "User Principal Name"

    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
        Write-Host ""
        Write-Host "User Principal Name cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($UserPrincipalName -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        Write-Host ""
        Write-Host "Invalid User Principal Name format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $Alias = Read-Host "Alias"

    if ([string]::IsNullOrWhiteSpace($Alias)) {
        $Alias = $UserPrincipalName.Split("@")[0]
    }

    $OrganizationalUnit = Read-Host "Organizational Unit (optional)"
    $MailboxDatabase = Read-Host "Mailbox Database (optional)"

    Write-Host ""
    Write-Host "Checking whether the shared mailbox already exists..." -ForegroundColor Cyan

    try {
        $ExistingMailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction SilentlyContinue

        if ($null -ne $ExistingMailbox) {
            Write-Host ""
            Write-Host "A mailbox with this identity already exists." -ForegroundColor Red
            Write-Host "Name : $($ExistingMailbox.DisplayName)" -ForegroundColor Yellow
            Write-Host "Type : $($ExistingMailbox.RecipientTypeDetails)" -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }
    catch {
        Write-Verbose $_.Exception.Message
    }

    try {
        $ExistingUser = Get-User -Identity $UserPrincipalName -ErrorAction SilentlyContinue

        if ($null -ne $ExistingUser) {
            Write-Host ""
            Write-Host "An existing recipient or user already uses this identity." -ForegroundColor Red
            Write-Host "Name : $($ExistingUser.Name)" -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }
    catch {
        Write-Verbose $_.Exception.Message
    }

    Write-Host ""
    Write-Host "Shared mailbox configuration:" -ForegroundColor Cyan
    Write-Host "  Name                 : $Name"
    Write-Host "  Display Name         : $DisplayName"
    Write-Host "  User Principal Name  : $UserPrincipalName"
    Write-Host "  Alias                : $Alias"

    if (-not [string]::IsNullOrWhiteSpace($OrganizationalUnit)) {
        Write-Host "  Organizational Unit  : $OrganizationalUnit"
    }
    else {
        Write-Host "  Organizational Unit  : Default"
    }

    if (-not [string]::IsNullOrWhiteSpace($MailboxDatabase)) {
        Write-Host "  Mailbox Database     : $MailboxDatabase"
    }
    else {
        Write-Host "  Mailbox Database     : Automatic"
    }

    Write-Host ""
    Write-Host "The shared mailbox will be created without a user password." -ForegroundColor Yellow
    Write-Host "Members and mailbox permissions can be configured afterwards." -ForegroundColor Yellow
    Write-Host ""

    $Confirmation = Read-Host "Type CREATE to continue"

    if ($Confirmation -cne "CREATE") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    $MailboxParameters = @{
        Shared             = $true
        Name               = $Name
        DisplayName        = $DisplayName
        UserPrincipalName  = $UserPrincipalName
        Alias              = $Alias
        Confirm            = $false
        ErrorAction        = "Stop"
    }

    if (-not [string]::IsNullOrWhiteSpace($OrganizationalUnit)) {
        $MailboxParameters["OrganizationalUnit"] = $OrganizationalUnit
    }

    if (-not [string]::IsNullOrWhiteSpace($MailboxDatabase)) {
        $MailboxParameters["Database"] = $MailboxDatabase
    }

    try {
        New-Mailbox @MailboxParameters | Out-Null

        Write-Host ""
        Write-Host "Shared mailbox created successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Name        : $DisplayName" -ForegroundColor Cyan
        Write-Host "Alias       : $Alias" -ForegroundColor Cyan
        Write-Host "UPN         : $UserPrincipalName" -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to create shared mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}