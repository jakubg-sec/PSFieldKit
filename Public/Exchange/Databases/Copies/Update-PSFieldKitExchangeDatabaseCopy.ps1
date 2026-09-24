function Update-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$SourceServer,

        [Parameter()]
        [switch]$DatabaseOnly,

        [Parameter()]
        [switch]$CatalogOnly,

        [Parameter()]
        [switch]$DeleteExistingFiles,

        [Parameter()]
        [switch]$SafeDeleteExistingFiles,

        [Parameter()]
        [switch]$BeginSeed,

        [Parameter()]
        [switch]$ManualResume,

        [Parameter()]
        [switch]$NoThrottle,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Update-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Update-MailboxDatabaseCopy' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        $Identity = Read-Host "Enter database copy identity (Database\Server)"

    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nDatabase copy identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ($Identity -notmatch '\\') {

        Write-Host "`nInvalid database copy identity." -ForegroundColor Red
        Write-Host "Use the following format: DatabaseName\ServerName" -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    if ($DatabaseOnly -and $CatalogOnly) {

        Write-Host "`nDatabaseOnly and CatalogOnly cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ($DeleteExistingFiles -and $SafeDeleteExistingFiles) {

        Write-Host "`nDeleteExistingFiles and SafeDeleteExistingFiles cannot be used together." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        $CopyStatus = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop

    }
    catch {

        Write-Host "`nDatabase copy '$Identity' was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    $IdentityParts = $Identity.Split('\', 2)

    $DatabaseName = $IdentityParts[0]
    $ServerName = $IdentityParts[1]

    $CurrentStatus = [string]$CopyStatus.Status
    $CurrentContentIndex = [string]$CopyStatus.ContentIndexState

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Update Database Copy              |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $DatabaseName)
    Write-Host ("|  Server   : {0,-33}|" -f $ServerName)
    Write-Host ("|  Status   : {0,-33}|" -f $CurrentStatus)
    Write-Host ("|  Index    : {0,-33}|" -f $CurrentContentIndex)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nUPDATE MODE" -ForegroundColor DarkCyan

    if ($DatabaseOnly) {

        Write-Host "Mode : Database only" -ForegroundColor Yellow
        Write-Host "Effect: The mailbox database files will be seeded/reseeded."

    }
    elseif ($CatalogOnly) {

        Write-Host "Mode : Catalog only" -ForegroundColor Yellow
        Write-Host "Effect: The Content Index catalog will be seeded/reseeded."

    }
    else {

        Write-Host "Mode : Database + Content Index" -ForegroundColor Yellow
        Write-Host "Effect: Both database files and Content Index will be seeded/reseeded."

    }

    if (-not [string]::IsNullOrWhiteSpace($SourceServer)) {
        Write-Host ("Source Server      : {0}" -f $SourceServer)
    }
    else {
        Write-Host "Source Server      : Automatic"
    }

    if ($DeleteExistingFiles) {
        Write-Host "Delete Existing    : Yes" -ForegroundColor Yellow
    }
    elseif ($SafeDeleteExistingFiles) {
        Write-Host "Safe Delete        : Yes" -ForegroundColor Yellow
    }
    else {
        Write-Host "Delete Existing    : No"
    }

    Write-Host ("Begin Seed         : {0}" -f $BeginSeed.IsPresent)
    Write-Host ("Manual Resume      : {0}" -f $ManualResume.IsPresent)
    Write-Host ("No Throttle        : {0}" -f $NoThrottle.IsPresent)
    Write-Host ("Force              : {0}" -f $Force.IsPresent)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "WARNING" -ForegroundColor Red
    Write-Host "Seeding can generate significant network and disk I/O." -ForegroundColor Yellow

    if ($DeleteExistingFiles) {
        Write-Host "Existing database files may be deleted before seeding." -ForegroundColor Red
    }

    Write-Host ""

    $Confirmation = Read-Host "Update database copy '$Identity'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nUpdating mailbox database copy '$Identity'..." -ForegroundColor Yellow

        $UpdateParameters = @{
            Identity    = $Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($SourceServer)) {
            $UpdateParameters['SourceServer'] = $SourceServer
        }

        if ($DatabaseOnly) {
            $UpdateParameters['DatabaseOnly'] = $true
        }

        if ($CatalogOnly) {
            $UpdateParameters['CatalogOnly'] = $true
        }

        if ($DeleteExistingFiles) {
            $UpdateParameters['DeleteExistingFiles'] = $true
        }

        if ($SafeDeleteExistingFiles) {
            $UpdateParameters['SafeDeleteExistingFiles'] = $true
        }

        if ($BeginSeed) {
            $UpdateParameters['BeginSeed'] = $true
        }

        if ($ManualResume) {
            $UpdateParameters['ManualResume'] = $true
        }

        if ($NoThrottle) {
            $UpdateParameters['NoThrottle'] = $true
        }

        if ($Force) {
            $UpdateParameters['Force'] = $true
        }

        if ($WhatIf) {
            $UpdateParameters['WhatIf'] = $true
        }

        Update-MailboxDatabaseCopy @UpdateParameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        if ($BeginSeed) {

            Write-Host "`nSeeding operation was started asynchronously." -ForegroundColor Green
            Write-Host "The seed operation is running in the background." -ForegroundColor Yellow

        }
        else {

            Write-Host "`nDatabase copy update completed successfully." -ForegroundColor Green

        }

    }
    catch {

        Write-Host "`nFailed to update database copy '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nChecking database copy status..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "VERIFICATION" -ForegroundColor DarkCyan

        Write-Host ("Database             : {0}" -f $DatabaseName)
        Write-Host ("Server               : {0}" -f $ServerName)
        Write-Host ("Status               : {0}" -f $Verification.Status)
        Write-Host ("Content Index        : {0}" -f $Verification.ContentIndexState)
        Write-Host ("Copy Queue Length    : {0}" -f $Verification.CopyQueueLength)
        Write-Host ("Replay Queue Length  : {0}" -f $Verification.ReplayQueueLength)

        if ($Verification.PSObject.Properties.Name -contains 'LastInspectedLogTime') {
            Write-Host ("Last Inspected Log   : {0}" -f $Verification.LastInspectedLogTime)
        }

        if ($Verification.PSObject.Properties.Name -contains 'LastCopiedLogTime') {
            Write-Host ("Last Copied Log      : {0}" -f $Verification.LastCopiedLogTime)
        }

        if ($Verification.PSObject.Properties.Name -contains 'LastReplayedLogTime') {
            Write-Host ("Last Replayed Log    : {0}" -f $Verification.LastReplayedLogTime)
        }

        if (
            $Verification.Status -eq 'Healthy' -and
            $Verification.ContentIndexState -eq 'Healthy'
        ) {

            Write-Host "`nDatabase copy is HEALTHY." -ForegroundColor Green

        }
        elseif ($BeginSeed) {

            Write-Host "`nSeed operation is in progress or has not reached Healthy yet." -ForegroundColor Yellow

        }
        else {

            Write-Host "`nDatabase copy is not currently Healthy." -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host "`nUpdate completed, but database copy status could not be verified." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}