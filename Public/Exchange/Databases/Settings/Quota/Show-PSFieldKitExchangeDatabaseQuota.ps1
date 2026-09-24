function Show-PSFieldKitExchangeDatabaseQuota {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|              Database Quotas                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nMAILBOX QUOTAS" -ForegroundColor DarkCyan
    Write-Host ("Issue Warning Quota       : {0}" -f $Database.IssueWarningQuota)
    Write-Host ("Prohibit Send Quota       : {0}" -f $Database.ProhibitSendQuota)
    Write-Host ("Prohibit Send/Receive     : {0}" -f $Database.ProhibitSendReceiveQuota)

    Write-Host "`nRECOVERABLE ITEMS" -ForegroundColor DarkCyan
    Write-Host ("Warning Quota             : {0}" -f $Database.RecoverableItemsWarningQuota)
    Write-Host ("Recoverable Items Quota   : {0}" -f $Database.RecoverableItemsQuota)

    Write-Host "`nQUOTA RELATIONSHIPS" -ForegroundColor DarkCyan
    Write-Host "Issue Warning <= Prohibit Send/Receive"
    Write-Host "Prohibit Send <= Prohibit Send/Receive"
    Write-Host "Recoverable Warning <= Recoverable Items"

    Write-Host ""
    Write-Host "These database quotas apply to mailboxes that use database quota defaults." -ForegroundColor DarkGray

    Read-Host "`nPress Enter to continue" | Out-Null
}