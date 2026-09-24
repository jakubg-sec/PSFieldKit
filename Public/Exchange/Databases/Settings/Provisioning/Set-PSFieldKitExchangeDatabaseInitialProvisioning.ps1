function Set-PSFieldKitExchangeDatabaseInitialProvisioning {
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

    $SetMailboxDatabaseCommand = Get-Command Set-MailboxDatabase -ErrorAction SilentlyContinue
    if ($SetMailboxDatabaseCommand.Parameters.Keys -notcontains 'IsExcludedFromInitialProvisioning') {
        Write-Host "`nThe current Exchange version does not expose 'IsExcludedFromInitialProvisioning'." -ForegroundColor Red
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
        $Database = Get-MailboxDatabase -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Database.PSObject.Properties.Name -notcontains 'IsExcludedFromInitialProvisioning') {
        Write-Host "`nThe database does not expose 'IsExcludedFromInitialProvisioning'." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentValue = [bool]$Database.IsExcludedFromInitialProvisioning

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Initial Mailbox Provisioning           |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 33) {
        $DisplayName = $DisplayName.Substring(0, 30) + "..."
    }
    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTINGS" -ForegroundColor DarkCyan
    if ($CurrentValue) {
        Write-Host "Initial Provisioning : Excluded"
    }
    else {
        Write-Host "Initial Provisioning : Enabled"
    }

    Write-Host "`nPROVISIONING ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable initial provisioning"
    Write-Host "[2] Exclude from initial provisioning"
    Write-Host "[0] Cancel"

    $Selection = Read-Host "`nSelect option"

    if ($Selection -eq '0') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    if ($Selection -notmatch '^[12]$') {
        Write-Host "`nInvalid option." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $NewValue = $Selection -eq '2'

    if ($NewValue -eq $CurrentValue) {
        if ($NewValue) {
            Write-Host "`nInitial provisioning is already excluded for this database." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nInitial provisioning is already enabled for this database." -ForegroundColor Yellow
        }
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current : {0}" -f $(if ($CurrentValue) { "Excluded" } else { "Enabled" }))
    Write-Host ("New     : {0}" -f $(if ($NewValue) { "Excluded" } else { "Enabled" }))

    Write-Host "`nNOTE" -ForegroundColor DarkCyan
    Write-Host "This setting temporarily excludes the database from initial mailbox provisioning." -ForegroundColor DarkGray

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply initial provisioning change? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating initial mailbox provisioning..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                       = $Database.Identity
            IsExcludedFromInitialProvisioning = $NewValue
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

        Write-Host "`nInitial mailbox provisioning updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update initial mailbox provisioning." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Initial Provisioning : {0}" -f $(if ($Verification.IsExcludedFromInitialProvisioning) { "Excluded" } else { "Enabled" }))

        if ([bool]$Verification.IsExcludedFromInitialProvisioning -eq $NewValue) {
            Write-Host "`nInitial mailbox provisioning was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned provisioning state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nInitial provisioning was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}