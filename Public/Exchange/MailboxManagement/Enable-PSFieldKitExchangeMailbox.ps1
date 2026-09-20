function Enable-PSFieldKitExchangeMailbox {
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
    Write-Host "|                 Enable Mailbox               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $UserIdentity = Read-Host "Enter existing AD user"

    if ([string]::IsNullOrWhiteSpace($UserIdentity)) {
        Write-Host ""
        Write-Host "User identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $User = Get-User -Identity $UserIdentity -ErrorAction Stop

        Write-Host ""
        Write-Host "User selected:" -ForegroundColor Cyan
        Write-Host "  Name        : $($User.Name)"
        Write-Host "  Display Name: $($User.DisplayName)"
        Write-Host "  Recipient   : $($User.RecipientTypeDetails)"
        Write-Host ""

        $ExistingMailbox = Get-Mailbox -Identity $User.Identity -ErrorAction SilentlyContinue

        if ($null -ne $ExistingMailbox) {
            Write-Host "This user already has a mailbox." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $Alias = Read-Host "Alias (optional)"

        $DisplayName = Read-Host "Display Name (optional)"

        $Database = Read-Host "Mailbox Database (optional)"

        Write-Host ""
        Write-Host "Mailbox configuration:" -ForegroundColor Cyan
        Write-Host "  User         : $($User.Name)"
        Write-Host "  Alias        : $(if ([string]::IsNullOrWhiteSpace($Alias)) { "Automatic" } else { $Alias })"
        Write-Host "  Display Name : $(if ([string]::IsNullOrWhiteSpace($DisplayName)) { "Automatic" } else { $DisplayName })"
        Write-Host "  Database     : $(if ([string]::IsNullOrWhiteSpace($Database)) { "Automatic" } else { $Database })"
        Write-Host ""

        $Confirmation = Read-Host "Type ENABLE to continue"

        if ($Confirmation -cne "ENABLE") {
            Write-Host ""
            Write-Host "Mailbox enable operation cancelled." -ForegroundColor Yellow
            return
        }

        $EnableParameters = @{
            Identity    = $User.Identity
            ErrorAction = "Stop"
        }

        if (-not [string]::IsNullOrWhiteSpace($Alias)) {
            $EnableParameters["Alias"] = $Alias
        }

        if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
            $EnableParameters["DisplayName"] = $DisplayName
        }

        if (-not [string]::IsNullOrWhiteSpace($Database)) {
            $EnableParameters["Database"] = $Database
        }

        Write-Host ""
        Write-Host "Enabling mailbox..." -ForegroundColor Yellow

        $Mailbox = Enable-Mailbox @EnableParameters

        Write-Host ""
        Write-Host "Mailbox enabled successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Name         : $($Mailbox.DisplayName)" -ForegroundColor White
        Write-Host "Alias        : $($Mailbox.Alias)" -ForegroundColor White
        Write-Host "Primary SMTP : $($Mailbox.PrimarySmtpAddress)" -ForegroundColor White
        Write-Host "Database     : $($Mailbox.Database)" -ForegroundColor White
    }
    catch {
        Write-Host ""
        Write-Host "Failed to enable mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}