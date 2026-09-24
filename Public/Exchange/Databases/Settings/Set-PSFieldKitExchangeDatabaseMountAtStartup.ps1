function Set-PSFieldKitExchangeDatabaseMountAtStartup {
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
            -Status `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentState = [bool]$Database.MountAtStartup
    $CurrentText = if ($CurrentState) { "Enabled" } else { "Disabled" }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Mount Database at Startup         |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan
    Write-Host ("Mount At Startup : {0}" -f $CurrentText)

    Write-Host "`nSELECT ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable Mount at Startup"
    Write-Host "[2] Disable Mount at Startup"
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
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    if ($NewState -eq $CurrentState) {
        Write-Host "`nMount at startup is already $CurrentText." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current State : {0}" -f $CurrentText)
    Write-Host ("New State     : {0}" -f $(if ($NewState) { "Enabled" } else { "Disabled" }))

    if (-not $NewState) {
        Write-Host ""
        Write-Host "WARNING: The database will not be automatically mounted when the Microsoft Exchange Information Store service starts." -ForegroundColor Yellow
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply this setting to '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Mount At Startup..." -ForegroundColor Yellow

        $Parameters = @{
            Identity        = $Database.Identity
            MountAtStartup = $NewState
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

        Write-Host "`nMount at startup setting updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Mount At Startup." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -Status `
            -ErrorAction Stop

        $VerificationText = if ($Verification.MountAtStartup) {
            "Enabled"
        }
        else {
            "Disabled"
        }

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Mount At Startup : {0}" -f $VerificationText)

        if ([bool]$Verification.MountAtStartup -eq $NewState) {
            Write-Host "`nMount at startup was changed successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nMount at startup was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}