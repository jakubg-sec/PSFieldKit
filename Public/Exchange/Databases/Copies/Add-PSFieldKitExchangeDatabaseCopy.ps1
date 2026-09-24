function Add-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$MailboxServer,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$ActivationPreference,

        [Parameter()]
        [string]$ReplayLagTime,

        [Parameter()]
        [string]$ReplayLagMaxDelay,

        [Parameter()]
        [string]$TruncationLagTime,

        [Parameter()]
        [switch]$SeedingPostponed,

        [Parameter()]
        [switch]$ConfigurationOnly,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Add-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Add-MailboxDatabaseCopy' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        $Identity = Read-Host "Enter mailbox database name"

    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ([string]::IsNullOrWhiteSpace($MailboxServer)) {

        $MailboxServer = Read-Host "Enter target Mailbox server"

    }

    if ([string]::IsNullOrWhiteSpace($MailboxServer)) {

        Write-Host "`nMailbox server cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -ErrorAction Stop

    }
    catch {

        Write-Host "`nMailbox database '$Identity' was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        $TargetServer = Get-ExchangeServer `
            -Identity $MailboxServer `
            -ErrorAction Stop

    }
    catch {

        Write-Host "`nMailbox server '$MailboxServer' was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        $ExistingCopy = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop |
            Where-Object {
                $_.MailboxServerName -eq $TargetServer.Name
            }

        if ($null -ne $ExistingCopy) {

            Write-Host "`nA copy of database '$Identity' already exists on '$($TargetServer.Name)'." -ForegroundColor Red

            Read-Host "Press Enter to continue" | Out-Null
            return

        }

    }
    catch {

        Write-Host "`nUnable to verify existing database copies." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Add Database Copy                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $Database.Name)
    Write-Host ("|  Server   : {0,-33}|" -f $TargetServer.Name)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCONFIGURATION" -ForegroundColor DarkCyan

    if ($PSBoundParameters.ContainsKey('ActivationPreference')) {
        Write-Host ("Activation Preference : {0}" -f $ActivationPreference)
    }
    else {
        Write-Host "Activation Preference : Default"
    }

    if ($PSBoundParameters.ContainsKey('ReplayLagTime')) {
        Write-Host ("Replay Lag Time      : {0}" -f $ReplayLagTime)
    }
    else {
        Write-Host "Replay Lag Time      : Default"
    }

    if ($PSBoundParameters.ContainsKey('ReplayLagMaxDelay')) {
        Write-Host ("Replay Lag Max Delay : {0}" -f $ReplayLagMaxDelay)
    }
    else {
        Write-Host "Replay Lag Max Delay : Default"
    }

    if ($PSBoundParameters.ContainsKey('TruncationLagTime')) {
        Write-Host ("Truncation Lag Time  : {0}" -f $TruncationLagTime)
    }
    else {
        Write-Host "Truncation Lag Time  : Default"
    }

    Write-Host ("Seeding Postponed    : {0}" -f $SeedingPostponed.IsPresent)
    Write-Host ("Configuration Only   : {0}" -f $ConfigurationOnly.IsPresent)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Add database copy '$($Database.Name)' to '$($TargetServer.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nAdding mailbox database copy..." -ForegroundColor Yellow

        $Parameters = @{
            Identity      = $Database.Identity
            MailboxServer = $TargetServer.Name
            ErrorAction   = 'Stop'
            Confirm       = $false
        }

        if ($PSBoundParameters.ContainsKey('ActivationPreference')) {
            $Parameters['ActivationPreference'] = $ActivationPreference
        }

        if ($PSBoundParameters.ContainsKey('ReplayLagTime')) {
            $Parameters['ReplayLagTime'] = $ReplayLagTime
        }

        if ($PSBoundParameters.ContainsKey('ReplayLagMaxDelay')) {
            $Parameters['ReplayLagMaxDelay'] = $ReplayLagMaxDelay
        }

        if ($PSBoundParameters.ContainsKey('TruncationLagTime')) {
            $Parameters['TruncationLagTime'] = $TruncationLagTime
        }

        if ($SeedingPostponed) {
            $Parameters['SeedingPostponed'] = $true
        }

        if ($ConfigurationOnly) {
            $Parameters['ConfigurationOnly'] = $true
        }

        if ($WhatIf) {
            $Parameters['WhatIf'] = $true
        }

        Add-MailboxDatabaseCopy @Parameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No database copy was created." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nMailbox database copy was added successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to add mailbox database copy." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying database copy..." -ForegroundColor Yellow

        $CopyStatus = Get-MailboxDatabaseCopyStatus `
            -Identity "$($Database.Name)\$($TargetServer.Name)" `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "COPY STATUS" -ForegroundColor DarkCyan

        Write-Host ("Database             : {0}" -f $Database.Name)
        Write-Host ("Server               : {0}" -f $TargetServer.Name)
        Write-Host ("Status               : {0}" -f $CopyStatus.Status)
        Write-Host ("Content Index        : {0}" -f $CopyStatus.ContentIndexState)
        Write-Host ("Copy Queue Length    : {0}" -f $CopyStatus.CopyQueueLength)
        Write-Host ("Replay Queue Length  : {0}" -f $CopyStatus.ReplayQueueLength)

        if ($CopyStatus.Status -eq 'Healthy') {
            Write-Host "`nDatabase copy is HEALTHY." -ForegroundColor Green
        }
        else {
            Write-Host "`nDatabase copy was created, but its current status is '$($CopyStatus.Status)'." -ForegroundColor Yellow
        }

    }
    catch {

        Write-Host "`nDatabase copy was added, but its status could not be retrieved." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}