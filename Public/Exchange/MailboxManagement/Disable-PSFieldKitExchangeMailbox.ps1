function Disable-PSFieldKitExchangeMailbox {
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
    Write-Host "|                 Disable Mailbox              |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop

        Write-Host ""
        Write-Host "Mailbox selected:" -ForegroundColor Cyan
        Write-Host "  Name        : $($Mailbox.DisplayName)"
        Write-Host "  Alias       : $($Mailbox.Alias)"
        Write-Host "  Primary SMTP: $($Mailbox.PrimarySmtpAddress)"
        Write-Host "  Database    : $($Mailbox.Database)"
        Write-Host ""

        Write-Host "WARNING: This will disable the Exchange mailbox." -ForegroundColor Red
        Write-Host "The associated Active Directory account will not be removed." -ForegroundColor Yellow
        Write-Host "The mailbox will become disconnected from the user account." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type DISABLE to continue"

        if ($Confirmation -cne "DISABLE") {
            Write-Host ""
            Write-Host "Mailbox disable operation cancelled." -ForegroundColor Yellow
            return
        }

        Write-Host ""
        Write-Host "Disabling mailbox..." -ForegroundColor Yellow

        Disable-Mailbox -Identity $Mailbox.Identity -Confirm:$false -ErrorAction Stop

        Write-Host ""
        Write-Host "Mailbox disabled successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Mailbox : $($Mailbox.DisplayName)" -ForegroundColor White
        Write-Host "Alias   : $($Mailbox.Alias)" -ForegroundColor White
    }
    catch {
        Write-Host ""
        Write-Host "Failed to disable mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}