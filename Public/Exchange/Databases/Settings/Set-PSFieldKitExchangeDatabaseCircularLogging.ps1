function Set-PSFieldKitExchangeDatabaseCircularLogging {
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
        $Database = Get-MailboxDatabase -Identity $Identity -Status -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $CurrentState = [bool]$Database.CircularLoggingEnabled
    $CurrentText = if ($CurrentState) { "Enabled" } else { "Disabled" }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Circular Logging                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan
    Write-Host ("Circular Logging : {0}" -f $CurrentText)

    Write-Host "`nSELECT ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable Circular Logging"
    Write-Host "[2] Disable Circular Logging"
    Write-Host "[Enter] Keep current value"

    $Choice = Read-Host "Select option"

    if ([string]::IsNullOrWhiteSpace($Choice)) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    switch ($Choice) {
        '1' {
            $NewState = $true
        }
        '2' {
            $NewState = $false
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    if ($NewState -eq $CurrentState) {
        Write-Host "`nCircular logging is already $CurrentText." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $DatabaseCopies = @(
            Get-MailboxDatabaseCopyStatus `
                -Identity $Database.Name `
                -ErrorAction Stop
        )
    }
    catch {
        Write-Host "`nUnable to check database copies." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $HasMultipleCopies = $DatabaseCopies.Count -gt 1

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Circular Logging : {0}" -f $(if ($NewState) { "Enable" } else { "Disable" }))
    Write-Host ("Current State    : {0}" -f $CurrentText)
    Write-Host ("Database Copies  : {0}" -f $DatabaseCopies.Count)

    if ($HasMultipleCopies -and -not $NewState) {
        Write-Host ""
        Write-Host "WARNING: Disabling circular logging on a database with multiple copies affects log truncation and reseeding/replication scenarios." -ForegroundColor Yellow
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Set Circular Logging to '$NewState' on '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating circular logging..." -ForegroundColor Yellow

        $Parameters = @{
            Identity             = $Database.Identity
            CircularLoggingEnabled = $NewState
            Confirm              = $false
            ErrorAction          = 'Stop'
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

        Write-Host "`nCircular logging updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update circular logging." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -Status `
            -ErrorAction Stop

        $VerificationText = if ($Verification.CircularLoggingEnabled) {
            "Enabled"
        }
        else {
            "Disabled"
        }

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Circular Logging : {0}" -f $VerificationText)

        if ([bool]$Verification.CircularLoggingEnabled -eq $NewState) {
            Write-Host "`nCircular logging was changed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nCircular logging was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}