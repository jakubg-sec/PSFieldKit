function Set-PSFieldKitExchangeDatabaseAutoDAGMonitoring {
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
    if ($SetMailboxDatabaseCommand.Parameters.Keys -notcontains 'AutoDagExcludeFromMonitoring') {
        Write-Host "`nThe current Exchange version does not expose 'AutoDagExcludeFromMonitoring'." -ForegroundColor Red
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

    if ($Database.PSObject.Properties.Name -notcontains 'AutoDagExcludeFromMonitoring') {
        Write-Host "`nThe database does not expose 'AutoDagExcludeFromMonitoring'." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentValue = [bool]$Database.AutoDagExcludeFromMonitoring

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|           AutoDAG Monitoring                 |" -ForegroundColor Cyan
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

    $CurrentStatus = if ($CurrentValue) {
        "Excluded from monitoring"
    }
    else {
        "Monitored"
    }

    Write-Host ("AutoDAG Monitoring : {0}" -f $CurrentStatus)
    Write-Host ""
    Write-Host "When monitoring is enabled, Exchange can alert when a replicated database`nhas only one healthy copy available." -ForegroundColor DarkGray

    Write-Host "`nMONITORING ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable AutoDAG monitoring"
    Write-Host "[2] Exclude database from AutoDAG monitoring"
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
            Write-Host "`nThe database is already excluded from AutoDAG monitoring." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nAutoDAG monitoring is already enabled for this database." -ForegroundColor Yellow
        }
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan

    $NewStatus = if ($NewValue) {
        "Excluded from monitoring"
    }
    else {
        "Monitored"
    }

    Write-Host ("Current : {0}" -f $CurrentStatus)
    Write-Host ("New     : {0}" -f $NewStatus)

    if ($NewValue) {
        Write-Host ""
        Write-Host "WARNING: This suppresses the ServerOneCopyMonitor alert for this database." -ForegroundColor Yellow
        Write-Host "The database can have only one healthy copy without generating this alert." -ForegroundColor Yellow
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply AutoDAG monitoring change? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating AutoDAG monitoring..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                   = $Database.Identity
            AutoDagExcludeFromMonitoring = $NewValue
            Confirm                    = $false
            ErrorAction                = 'Stop'
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

        Write-Host "`nAutoDAG monitoring updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update AutoDAG monitoring." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan

        $VerificationStatus = if ($Verification.AutoDagExcludeFromMonitoring) {
            "Excluded from monitoring"
        }
        else {
            "Monitored"
        }

        Write-Host ("AutoDAG Monitoring : {0}" -f $VerificationStatus)

        if ([bool]$Verification.AutoDagExcludeFromMonitoring -eq $NewValue) {
            Write-Host "`nAutoDAG monitoring was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned monitoring state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nAutoDAG monitoring was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}