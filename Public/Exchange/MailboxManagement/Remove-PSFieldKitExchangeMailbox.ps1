function Remove-PSFieldKitExchangeMailbox {
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
    Write-Host "|                 Remove Mailbox               |" -ForegroundColor Cyan
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
        Write-Host "  Name         : $($Mailbox.DisplayName)"
        Write-Host "  Alias        : $($Mailbox.Alias)"
        Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
        Write-Host "  Database     : $($Mailbox.Database)"
        Write-Host ""

        Write-Host "WARNING: Remove-Mailbox removes the mailbox and the associated user account." -ForegroundColor Red
        Write-Host "The normal removal keeps the mailbox recoverable for the configured retention period." -ForegroundColor Yellow
        Write-Host ""

        $RemovalMode = Read-Host "Permanent deletion immediately? (Y/N)"

        $Permanent = $false

        if ($RemovalMode -match "^[Yy]$") {
            $Permanent = $true
        }

        Write-Host ""

        if ($Permanent) {
            Write-Host "PERMANENT deletion selected." -ForegroundColor Red
            Write-Host "The mailbox cannot be recovered after purge." -ForegroundColor Red
            Write-Host ""

            $Confirmation = Read-Host "Type REMOVE PERMANENT to continue"

            if ($Confirmation -cne "REMOVE PERMANENT") {
                Write-Host ""
                Write-Host "Mailbox removal cancelled." -ForegroundColor Yellow
                return
            }
        }
        else {
            Write-Host "Standard removal selected." -ForegroundColor Yellow
            Write-Host "The mailbox will remain recoverable according to mailbox retention settings." -ForegroundColor Yellow
            Write-Host ""

            $Confirmation = Read-Host "Type REMOVE to continue"

            if ($Confirmation -cne "REMOVE") {
                Write-Host ""
                Write-Host "Mailbox removal cancelled." -ForegroundColor Yellow
                return
            }
        }

        Write-Host ""
        Write-Host "Removing mailbox..." -ForegroundColor Yellow

        $RemoveParameters = @{
            Identity    = $Mailbox.Identity
            Confirm     = $false
            ErrorAction = "Stop"
        }

        if ($Permanent) {
            $RemoveParameters["Permanent"] = $true
        }

        Remove-Mailbox @RemoveParameters

        Write-Host ""

        if ($Permanent) {
            Write-Host "Mailbox permanently removed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Mailbox removed successfully." -ForegroundColor Green
            Write-Host "The mailbox remains recoverable according to the configured retention period." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "Mailbox : $($Mailbox.DisplayName)" -ForegroundColor White
        Write-Host "Alias   : $($Mailbox.Alias)" -ForegroundColor White
    }
    catch {
        Write-Host ""
        Write-Host "Failed to remove mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}