function Set-PSFieldKitExchangeDatabaseJournaling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity,
        [Parameter()]
        [string]$JournalRecipient,
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

    if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Mailbox' is not available." -ForegroundColor Red
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

    $CurrentJournalRecipient = $null

    if (
        $Database.PSObject.Properties.Name -contains 'JournalRecipient' -and
        $null -ne $Database.JournalRecipient
    ) {
        $CurrentJournalRecipient = [string]$Database.JournalRecipient
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Database Journaling                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan

    if ([string]::IsNullOrWhiteSpace($CurrentJournalRecipient)) {
        Write-Host "Journaling       : Disabled"
        Write-Host "Journal Recipient: None"
    }
    else {
        Write-Host "Journaling       : Enabled"
        Write-Host "Journal Recipient: $CurrentJournalRecipient"
    }

    Write-Host "`nSELECT ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable / Change Journaling"
    Write-Host "[2] Disable Journaling"
    Write-Host "[Enter] Keep current value"

    $Choice = Read-Host "Select option"

    if ([string]::IsNullOrWhiteSpace($Choice)) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    switch ($Choice) {
        '1' {
            if ([string]::IsNullOrWhiteSpace($JournalRecipient)) {
                $JournalRecipient = Read-Host "Enter journaling mailbox name, alias or email"
            }

            if ([string]::IsNullOrWhiteSpace($JournalRecipient)) {
                Write-Host "`nJournal recipient cannot be empty when enabling journaling." -ForegroundColor Yellow
                Read-Host "Press Enter to continue" | Out-Null
                return
            }

            try {
                $JournalMailbox = Get-Mailbox `
                    -Identity $JournalRecipient `
                    -ErrorAction Stop
            }
            catch {
                Write-Host "`nJournaling mailbox '$JournalRecipient' was not found." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
                Read-Host "Press Enter to continue" | Out-Null
                return
            }

            $NewJournalRecipient = [string]$JournalMailbox.Identity
        }
        '2' {
            $NewJournalRecipient = $null
        }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $CurrentDisplay = if ([string]::IsNullOrWhiteSpace($CurrentJournalRecipient)) {
        "Disabled"
    }
    else {
        $CurrentJournalRecipient
    }

    $NewDisplay = if ([string]::IsNullOrWhiteSpace($NewJournalRecipient)) {
        "Disabled"
    }
    else {
        $NewJournalRecipient
    }

    if ($CurrentDisplay -eq $NewDisplay) {
        Write-Host "`nThe database already has this journaling configuration." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host "Current : $CurrentDisplay"
    Write-Host "New     : $NewDisplay"

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply journaling configuration to '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating database journaling..." -ForegroundColor Yellow

        $Parameters = @{
            Identity        = $Database.Identity
            JournalRecipient = $NewJournalRecipient
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

        Write-Host "`nDatabase journaling updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update database journaling." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -ErrorAction Stop

        $VerificationJournalRecipient = $null

        if (
            $Verification.PSObject.Properties.Name -contains 'JournalRecipient' -and
            $null -ne $Verification.JournalRecipient
        ) {
            $VerificationJournalRecipient = [string]$Verification.JournalRecipient
        }

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan

        if ([string]::IsNullOrWhiteSpace($VerificationJournalRecipient)) {
            Write-Host "Journaling       : Disabled"
            Write-Host "Journal Recipient: None"
        }
        else {
            Write-Host "Journaling       : Enabled"
            Write-Host "Journal Recipient: $VerificationJournalRecipient"
        }

        if (
            [string]::IsNullOrWhiteSpace($NewJournalRecipient) -and
            [string]::IsNullOrWhiteSpace($VerificationJournalRecipient)
        ) {
            Write-Host "`nJournaling was disabled successfully." -ForegroundColor Green
        }
        elseif (
            -not [string]::IsNullOrWhiteSpace($NewJournalRecipient) -and
            $VerificationJournalRecipient -eq $NewJournalRecipient
        ) {
            Write-Host "`nJournaling was configured successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned journaling configuration does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nJournaling was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}