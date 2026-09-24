function Set-PSFieldKitExchangeDatabaseMaintenance {
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
        $Database = Get-MailboxDatabase -Identity $Identity -Status -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $SetCommand = Get-Command Set-MailboxDatabase -ErrorAction SilentlyContinue
    $SupportsIndexEnabled = $null -ne $SetCommand.Parameters['IndexEnabled']

    $CurrentBackgroundMaintenance = [bool]$Database.BackgroundDatabaseMaintenance
    $CurrentMountAtStartup = [bool]$Database.MountAtStartup
    $CurrentEventHistoryDays = 7

    if ($null -ne $Database.EventHistoryRetentionPeriod) {
        try {
            $CurrentEventHistoryDays = [math]::Floor($Database.EventHistoryRetentionPeriod.TotalDays)
        }
        catch {
            $CurrentEventHistoryDays = 7
        }
    }

    $CurrentIndexEnabled = $null

    if (
        $SupportsIndexEnabled -and
        $Database.PSObject.Properties.Name -contains 'IndexEnabled'
    ) {
        $CurrentIndexEnabled = [bool]$Database.IndexEnabled
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Database Maintenance               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                  |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTINGS" -ForegroundColor DarkCyan
    Write-Host ("Background Maintenance : {0}" -f $CurrentBackgroundMaintenance)
    Write-Host ("Mount At Startup       : {0}" -f $CurrentMountAtStartup)
    Write-Host ("Event History Retention: {0} days" -f $CurrentEventHistoryDays)

    if ($SupportsIndexEnabled) {
        if ($null -ne $CurrentIndexEnabled) {
            Write-Host ("Index Enabled          : {0}" -f $CurrentIndexEnabled)
        }
    }
    else {
        Write-Host "Index Enabled          : Not supported on this Exchange version" -ForegroundColor DarkYellow
    }

    Write-Host "`nBACKGROUND DATABASE MAINTENANCE" -ForegroundColor DarkCyan
    Write-Host "[1] Disabled"
    Write-Host "[2] Enabled"
    Write-Host "[Enter] Keep current value"
    $Choice = Read-Host "Select option"

    $NewBackgroundMaintenance = $null

    switch ($Choice) {
        '1' { $NewBackgroundMaintenance = $false }
        '2' { $NewBackgroundMaintenance = $true }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nMOUNT AT STARTUP" -ForegroundColor DarkCyan
    Write-Host "[1] Do not mount automatically"
    Write-Host "[2] Mount automatically"
    Write-Host "[Enter] Keep current value"
    $Choice = Read-Host "Select option"

    $NewMountAtStartup = $null

    switch ($Choice) {
        '1' { $NewMountAtStartup = $false }
        '2' { $NewMountAtStartup = $true }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nEVENT HISTORY RETENTION" -ForegroundColor DarkCyan
    Write-Host "Enter number of days (1-30)."
    Write-Host "[Enter] Keep current value"
    $RetentionInput = Read-Host "Retention days"

    $NewEventHistoryDays = $null

    if (-not [string]::IsNullOrWhiteSpace($RetentionInput)) {
        $ParsedDays = 0

        if (-not [int]::TryParse($RetentionInput, [ref]$ParsedDays)) {
            Write-Host "`nRetention must be a whole number of days." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($ParsedDays -lt 1 -or $ParsedDays -gt 30) {
            Write-Host "`nEvent history retention must be between 1 and 30 days." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        $NewEventHistoryDays = $ParsedDays
    }

    $NewIndexEnabled = $null

    if ($SupportsIndexEnabled) {
        Write-Host "`nEXCHANGE SEARCH INDEX" -ForegroundColor DarkCyan
        Write-Host "[1] Disabled"
        Write-Host "[2] Enabled"
        Write-Host "[Enter] Keep current value"
        $Choice = Read-Host "Select option"

        switch ($Choice) {
            '1' { $NewIndexEnabled = $false }
            '2' { $NewIndexEnabled = $true }
            '' { }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    $Changes = @()

    if ($null -ne $NewBackgroundMaintenance) {
        $Changes += "Background Maintenance : $NewBackgroundMaintenance"
    }

    if ($null -ne $NewMountAtStartup) {
        $Changes += "Mount At Startup       : $NewMountAtStartup"
    }

    if ($null -ne $NewEventHistoryDays) {
        $Changes += "Event History Retention: $NewEventHistoryDays days"
    }

    if ($null -ne $NewIndexEnabled) {
        $Changes += "Index Enabled          : $NewIndexEnabled"
    }

    if ($Changes.Count -eq 0) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGES" -ForegroundColor DarkCyan

    foreach ($Change in $Changes) {
        Write-Host $Change
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Apply these maintenance settings to '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating database maintenance settings..." -ForegroundColor Yellow

        $Parameters = @{
            Identity    = $Database.Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($null -ne $NewBackgroundMaintenance) {
            $Parameters['BackgroundDatabaseMaintenance'] = $NewBackgroundMaintenance
        }

        if ($null -ne $NewMountAtStartup) {
            $Parameters['MountAtStartup'] = $NewMountAtStartup
        }

        if ($null -ne $NewEventHistoryDays) {
            $Parameters['EventHistoryRetentionPeriod'] = "{0}.00:00:00" -f $NewEventHistoryDays
        }

        if ($null -ne $NewIndexEnabled) {
            $Parameters['IndexEnabled'] = $NewIndexEnabled
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

        Write-Host "`nDatabase maintenance settings updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update database maintenance settings." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -Status `
            -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Background Maintenance : {0}" -f $Verification.BackgroundDatabaseMaintenance)
        Write-Host ("Mount At Startup       : {0}" -f $Verification.MountAtStartup)
        Write-Host ("Event History Retention: {0}" -f $Verification.EventHistoryRetentionPeriod)

        if (
            $SupportsIndexEnabled -and
            $Verification.PSObject.Properties.Name -contains 'IndexEnabled'
        ) {
            Write-Host ("Index Enabled          : {0}" -f $Verification.IndexEnabled)
        }
    }
    catch {
        Write-Host "`nSettings were changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}