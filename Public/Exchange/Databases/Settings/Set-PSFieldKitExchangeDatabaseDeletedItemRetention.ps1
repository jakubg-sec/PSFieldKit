function Set-PSFieldKitExchangeDatabaseDeletedItemRetention {
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
        Read-Host "Press Enter to continue" | Out-Null
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

    $CurrentRetentionDays = 14

    if ($null -ne $Database.DeletedItemRetention) {
        try {
            $CurrentRetentionDays = [math]::Floor($Database.DeletedItemRetention.TotalDays)
        }
        catch {
            $CurrentRetentionDays = 14
        }
    }

    $CurrentRetainUntilBackup = $false

    if ($Database.PSObject.Properties.Name -contains 'RetainDeletedItemsUntilBackup') {
        $CurrentRetainUntilBackup = [bool]$Database.RetainDeletedItemsUntilBackup
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|        Deleted Item Retention                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTINGS" -ForegroundColor DarkCyan
    Write-Host ("Deleted Item Retention : {0} days" -f $CurrentRetentionDays)
    Write-Host ("Retain Until Backup   : {0}" -f $CurrentRetainUntilBackup)

    Write-Host "`nDELETED ITEM RETENTION" -ForegroundColor DarkCyan
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
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($RetentionDays -lt 0 -or $RetentionDays -gt 24855) {
            Write-Host "`nRetention must be between 0 and 24855 days." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nRETAIN UNTIL BACKUP" -ForegroundColor DarkCyan
    Write-Host "[1] No"
    Write-Host "[2] Yes"
    Write-Host "[Enter] Keep current value"

    $BackupChoice = Read-Host "Select option"

    $RetainUntilBackup = $CurrentRetainUntilBackup

    switch ($BackupChoice) {
        '1' {
            $RetainUntilBackup = $false
        }
        '2' {
            $RetainUntilBackup = $true
        }
        '' {
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    if (
        $RetentionDays -eq $CurrentRetentionDays -and
        $RetainUntilBackup -eq $CurrentRetainUntilBackup
    ) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGES" -ForegroundColor DarkCyan
    Write-Host ("Deleted Item Retention : {0} days" -f $RetentionDays)
    Write-Host ("Retain Until Backup   : {0}" -f $RetainUntilBackup)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Apply these settings to '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating deleted item retention..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                       = $Database.Identity
            DeletedItemRetention            = "{0}.00:00:00" -f $RetentionDays
            RetainDeletedItemsUntilBackup = $RetainUntilBackup
            Confirm                        = $false
            ErrorAction                    = 'Stop'
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

        Write-Host "`nDeleted item retention updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update deleted item retention." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Deleted Item Retention : {0}" -f $Verification.DeletedItemRetention)
        Write-Host ("Retain Until Backup   : {0}" -f $Verification.RetainDeletedItemsUntilBackup)
    }
    catch {
        Write-Host "`nSettings were changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}