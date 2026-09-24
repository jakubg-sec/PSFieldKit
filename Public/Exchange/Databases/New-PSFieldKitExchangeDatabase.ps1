function New-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Server,
        [Parameter()]
        [string]$EdbFilePath,
        [Parameter()]
        [string]$LogFolderPath,
        [Parameter()]
        [string]$OfflineAddressBook,
        [Parameter()]
        [switch]$ExcludedFromProvisioning,
        [Parameter()]
        [switch]$ExcludedFromInitialProvisioning,
        [Parameter()]
        [switch]$SuspendedFromProvisioning,
        [Parameter()]
        [switch]$AutoDagExcludeFromMonitoring,
        [Parameter()]
        [switch]$WhatIf
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command New-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'New-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Read-Host "Enter new mailbox database name"
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "`nDatabase name cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Name.Length -gt 64) {
        Write-Host "`nDatabase name cannot exceed 64 characters." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Server)) {
        if (
            $ExchangeContext.PSObject.Properties.Name -contains 'ServerName' -and
            -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
        ) {
            $Server = [string]$ExchangeContext.ServerName
        }
        else {
            $Server = Read-Host "Enter Exchange server"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Server)) {
        Write-Host "`nExchange server cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $ExistingDatabase = Get-MailboxDatabase -Identity $Name -ErrorAction SilentlyContinue

        if ($null -ne $ExistingDatabase) {
            Write-Host "`nA mailbox database named '$Name' already exists." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }
    catch {
        # Ignore lookup errors.
    }

    if ([string]::IsNullOrWhiteSpace($EdbFilePath)) {
        $EdbFilePath = Read-Host "Enter EDB file path (press Enter for default)"
    }

    if ([string]::IsNullOrWhiteSpace($LogFolderPath)) {
        $LogFolderPath = Read-Host "Enter log folder path (press Enter for default)"
    }

    if ([string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
        $OfflineAddressBook = Read-Host "Enter Offline Address Book (press Enter for default/none)"
    }

    if (-not $PSBoundParameters.ContainsKey('ExcludedFromProvisioning')) {
        Write-Host "`nExclude database from provisioning?" -ForegroundColor Cyan
        Write-Host "[1] No"
        Write-Host "[2] Yes"
        $Choice = Read-Host "Select option"

        switch ($Choice) {
            '1' {
                $ExcludedFromProvisioning = $false
            }
            '2' {
                $ExcludedFromProvisioning = $true
            }
            '' {
                $ExcludedFromProvisioning = $false
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    if (-not $PSBoundParameters.ContainsKey('ExcludedFromInitialProvisioning')) {
        Write-Host "`nExclude database from initial provisioning?" -ForegroundColor Cyan
        Write-Host "[1] No"
        Write-Host "[2] Yes"
        $Choice = Read-Host "Select option"

        switch ($Choice) {
            '1' {
                $ExcludedFromInitialProvisioning = $false
            }
            '2' {
                $ExcludedFromInitialProvisioning = $true
            }
            '' {
                $ExcludedFromInitialProvisioning = $false
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    if (-not $PSBoundParameters.ContainsKey('SuspendedFromProvisioning')) {
        Write-Host "`nSuspend database from provisioning?" -ForegroundColor Cyan
        Write-Host "[1] No"
        Write-Host "[2] Yes"
        $Choice = Read-Host "Select option"

        switch ($Choice) {
            '1' {
                $SuspendedFromProvisioning = $false
            }
            '2' {
                $SuspendedFromProvisioning = $true
            }
            '' {
                $SuspendedFromProvisioning = $false
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    if (-not $PSBoundParameters.ContainsKey('AutoDagExcludeFromMonitoring')) {
        Write-Host "`nExclude database from AutoDAG monitoring?" -ForegroundColor Cyan
        Write-Host "[1] No"
        Write-Host "[2] Yes"
        $Choice = Read-Host "Select option"

        switch ($Choice) {
            '1' {
                $AutoDagExcludeFromMonitoring = $false
            }
            '2' {
                $AutoDagExcludeFromMonitoring = $true
            }
            '' {
                $AutoDagExcludeFromMonitoring = $false
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             New Mailbox Database             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Name   : {0,-35}|" -f $Name)
    Write-Host ("|  Server : {0,-35}|" -f $Server)
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCONFIGURATION" -ForegroundColor DarkCyan

    if ([string]::IsNullOrWhiteSpace($EdbFilePath)) {
        Write-Host "EDB Path              : Default"
    }
    else {
        Write-Host "EDB Path              : $EdbFilePath"
    }

    if ([string]::IsNullOrWhiteSpace($LogFolderPath)) {
        Write-Host "Log Folder            : Default"
    }
    else {
        Write-Host "Log Folder            : $LogFolderPath"
    }

    if ([string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
        Write-Host "Offline Address Book  : Default / None"
    }
    else {
        Write-Host "Offline Address Book  : $OfflineAddressBook"
    }

    Write-Host ("Excluded Provisioning : {0}" -f $ExcludedFromProvisioning.IsPresent)
    Write-Host ("Initial Provisioning  : {0}" -f $ExcludedFromInitialProvisioning.IsPresent)
    Write-Host ("Suspended Provisioning: {0}" -f $SuspendedFromProvisioning.IsPresent)
    Write-Host ("Auto DAG Monitoring   : {0}" -f $AutoDagExcludeFromMonitoring.IsPresent)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Create mailbox database '$Name'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nCreating mailbox database '$Name'..." -ForegroundColor Yellow

        $NewDatabaseParameters = @{
            Name        = $Name
            Server      = $Server
            ErrorAction = 'Stop'
            Confirm     = $false
        }

        if (-not [string]::IsNullOrWhiteSpace($EdbFilePath)) {
            $NewDatabaseParameters['EdbFilePath'] = $EdbFilePath
        }

        if (-not [string]::IsNullOrWhiteSpace($LogFolderPath)) {
            $NewDatabaseParameters['LogFolderPath'] = $LogFolderPath
        }

        if (-not [string]::IsNullOrWhiteSpace($OfflineAddressBook)) {
            $NewDatabaseParameters['OfflineAddressBook'] = $OfflineAddressBook
        }

        if ($ExcludedFromProvisioning) {
            $NewDatabaseParameters['IsExcludedFromProvisioning'] = $true
        }

        if ($ExcludedFromInitialProvisioning) {
            $NewDatabaseParameters['IsExcludedFromInitialProvisioning'] = $true
        }

        if ($SuspendedFromProvisioning) {
            $NewDatabaseParameters['IsSuspendedFromProvisioning'] = $true
        }

        if ($AutoDagExcludeFromMonitoring) {
            $NewDatabaseParameters['AutoDagExcludeFromMonitoring'] = $true
        }

        if ($WhatIf) {
            $NewDatabaseParameters['WhatIf'] = $true
        }

        New-MailboxDatabase @NewDatabaseParameters

        if ($WhatIf) {
            Write-Host "`nWhatIf completed. No database was created." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "`nMailbox database created successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to create mailbox database '$Name'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nRetrieving created database information..." -ForegroundColor Yellow

        $CreatedDatabase = Get-MailboxDatabase `
            -Identity $Name `
            -Status `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "DATABASE" -ForegroundColor DarkCyan
        Write-Host ("Name                  : {0}" -f $CreatedDatabase.Name)
        Write-Host ("Server                : {0}" -f $CreatedDatabase.Server)
        Write-Host ("Mounted               : {0}" -f $CreatedDatabase.Mounted)
        Write-Host ("EDB Path              : {0}" -f $CreatedDatabase.EdbFilePath)
        Write-Host ("Log Folder            : {0}" -f $CreatedDatabase.LogFolderPath)
        Write-Host ("Excluded Provisioning : {0}" -f $CreatedDatabase.IsExcludedFromProvisioning)

        Write-Host "`nNOTE" -ForegroundColor DarkCyan
        Write-Host "The new mailbox database is created dismounted." -ForegroundColor Yellow
        Write-Host "Use the Mount Database option to mount it."
    }
    catch {
        Write-Host "`nDatabase was created, but its status could not be retrieved." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}