function Set-PSFieldKitExchangeDatabaseSettings {
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Set Database Settings               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGENERAL SETTINGS" -ForegroundColor DarkCyan

    Write-Host ("Current Allow File Restore        : {0}" -f $Database.AllowFileRestore)
    Write-Host ("Current Background Maintenance    : {0}" -f $Database.BackgroundDatabaseMaintenance)
    Write-Host ("Current Data Move Constraint      : {0}" -f $Database.DataMoveReplicationConstraint)
    Write-Host ("Current Retain Until Backup       : {0}" -f $Database.RetainDeletedItemsUntilBackup)

    Write-Host "`nAllow database restore from backup?" -ForegroundColor Cyan
    Write-Host "[1] No"
    Write-Host "[2] Yes"
    Write-Host "[Enter] Keep current value"
    $AllowFileRestoreChoice = Read-Host "Select option"

    $NewAllowFileRestore = $null

    switch ($AllowFileRestoreChoice) {
        '1' { $NewAllowFileRestore = $false }
        '2' { $NewAllowFileRestore = $true }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nEnable background database maintenance?" -ForegroundColor Cyan
    Write-Host "[1] No"
    Write-Host "[2] Yes"
    Write-Host "[Enter] Keep current value"
    $BackgroundMaintenanceChoice = Read-Host "Select option"

    $NewBackgroundMaintenance = $null

    switch ($BackgroundMaintenanceChoice) {
        '1' { $NewBackgroundMaintenance = $false }
        '2' { $NewBackgroundMaintenance = $true }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nData move replication constraint:" -ForegroundColor Cyan
    Write-Host "[1] None"
    Write-Host "[2] SecondCopy"
    Write-Host "[3] SecondDatacenter"
    Write-Host "[4] CINoReplication"
    Write-Host "[5] CISecondCopy"
    Write-Host "[6] CISecondDatacenter"
    Write-Host "[Enter] Keep current value"
    $DataMoveChoice = Read-Host "Select option"

    $NewDataMoveConstraint = $null

    switch ($DataMoveChoice) {
        '1' { $NewDataMoveConstraint = 'None' }
        '2' { $NewDataMoveConstraint = 'SecondCopy' }
        '3' { $NewDataMoveConstraint = 'SecondDatacenter' }
        '4' { $NewDataMoveConstraint = 'CINoReplication' }
        '5' { $NewDataMoveConstraint = 'CISecondCopy' }
        '6' { $NewDataMoveConstraint = 'CISecondDatacenter' }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nRetain deleted items until next database backup?" -ForegroundColor Cyan
    Write-Host "[1] No"
    Write-Host "[2] Yes"
    Write-Host "[Enter] Keep current value"
    $RetainUntilBackupChoice = Read-Host "Select option"

    $NewRetainUntilBackup = $null

    switch ($RetainUntilBackupChoice) {
        '1' { $NewRetainUntilBackup = $false }
        '2' { $NewRetainUntilBackup = $true }
        '' { }
        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    $Changes = @()

    if ($null -ne $NewAllowFileRestore) {
        $Changes += "Allow File Restore        : $NewAllowFileRestore"
    }

    if ($null -ne $NewBackgroundMaintenance) {
        $Changes += "Background Maintenance    : $NewBackgroundMaintenance"
    }

    if ($null -ne $NewDataMoveConstraint) {
        $Changes += "Data Move Constraint      : $NewDataMoveConstraint"
    }

    if ($null -ne $NewRetainUntilBackup) {
        $Changes += "Retain Until Backup       : $NewRetainUntilBackup"
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

    $Confirmation = Read-Host "Apply these changes to '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating database settings..." -ForegroundColor Yellow

        $Parameters = @{
            Identity    = $Database.Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($null -ne $NewAllowFileRestore) {
            $Parameters['AllowFileRestore'] = $NewAllowFileRestore
        }

        if ($null -ne $NewBackgroundMaintenance) {
            $Parameters['BackgroundDatabaseMaintenance'] = $NewBackgroundMaintenance
        }

        if ($null -ne $NewDataMoveConstraint) {
            $Parameters['DataMoveReplicationConstraint'] = $NewDataMoveConstraint
        }

        if ($null -ne $NewRetainUntilBackup) {
            $Parameters['RetainDeletedItemsUntilBackup'] = $NewRetainUntilBackup
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

        Write-Host "`nDatabase settings updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update database settings." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -Status -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Allow File Restore        : {0}" -f $Verification.AllowFileRestore)
        Write-Host ("Background Maintenance   : {0}" -f $Verification.BackgroundDatabaseMaintenance)
        Write-Host ("Data Move Constraint     : {0}" -f $Verification.DataMoveReplicationConstraint)
        Write-Host ("Retain Until Backup      : {0}" -f $Verification.RetainDeletedItemsUntilBackup)
    }
    catch {
        Write-Host "`nSettings were changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}