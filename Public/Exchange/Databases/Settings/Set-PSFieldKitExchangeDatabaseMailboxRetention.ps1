function Set-PSFieldKitExchangeDatabaseMailboxRetention {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity,
        [Parameter()]
        [switch]$WhatIf
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Set-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Set-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
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
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $CurrentRetentionDays = 30

    if ($null -ne $Database.MailboxRetention) {
        try {
            $CurrentRetentionDays = [math]::Floor($Database.MailboxRetention.TotalDays)
        }
        catch {
            $CurrentRetentionDays = 30
        }
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Mailbox Retention                  |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan
    Write-Host ("Deleted Mailbox Retention : {0} days" -f $CurrentRetentionDays)

    Write-Host "`nMAILBOX RETENTION" -ForegroundColor DarkCyan
    Write-Host "Enter number of days."
    Write-Host "[Enter] Keep current value"

    $RetentionInput = Read-Host "Retention days"

    if ([string]::IsNullOrWhiteSpace($RetentionInput)) {
        $RetentionDays = $CurrentRetentionDays
    }
    else {
        $RetentionDays = 0

        if (-not [int]::TryParse($RetentionInput, [ref]$RetentionDays)) {
            Write-Host "`nRetention must be a whole number of days." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($RetentionDays -lt 0 -or $RetentionDays -gt 24855) {
            Write-Host "`nRetention must be between 0 and 24855 days." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    if ($RetentionDays -eq $CurrentRetentionDays) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Deleted Mailbox Retention : {0} days" -f $RetentionDays)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Set mailbox retention for '$($Database.Name)' to $RetentionDays days? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating mailbox retention..." -ForegroundColor Yellow

        $Parameters = @{
            Identity        = $Database.Identity
            MailboxRetention = "{0}.00:00:00" -f $RetentionDays
            Confirm         = $false
            ErrorAction     = 'Stop'
        }

        if ($WhatIf) {
            $Parameters['WhatIf'] = $true
        }

        Set-MailboxDatabase @Parameters

        if ($WhatIf) {
            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "`nMailbox retention updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update mailbox retention." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Deleted Mailbox Retention : {0}" -f $Verification.MailboxRetention)
    }
    catch {
        Write-Host "`nMailbox retention was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}