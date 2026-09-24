function Move-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [string]$ActivateOnServer,

        [Parameter()]
        [ValidateSet(
            'None',
            'Lossless',
            'GoodAvailability',
            'BestAvailability',
            'BestEffort'
        )]
        [string]$MountDialOverride,

        [Parameter()]
        [string]$MoveComment,

        [Parameter()]
        [switch]$SkipActiveCopyChecks,

        [Parameter()]
        [switch]$SkipClientExperienceChecks,

        [Parameter()]
        [switch]$SkipCpuChecks,

        [Parameter()]
        [switch]$SkipHealthChecks,

        [Parameter()]
        [switch]$SkipLagChecks,

        [Parameter()]
        [switch]$SkipMaximumActiveDatabasesChecks,

        [Parameter()]
        [switch]$SkipMoveSuppressionChecks,

        [Parameter()]
        [switch]$TerminateOnWarning,

        [Parameter()]
        [switch]$SkipAllChecks,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Move-ActiveMailboxDatabase -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Move-ActiveMailboxDatabase' is not available." -ForegroundColor Red
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

    if ([string]::IsNullOrWhiteSpace($ActivateOnServer)) {

        $ActivateOnServer = Read-Host "Enter target Mailbox server"

    }

    if ([string]::IsNullOrWhiteSpace($ActivateOnServer)) {

        Write-Host "`nTarget Mailbox server cannot be empty." -ForegroundColor Yellow
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

        Write-Host "`nMailbox database '$Identity' was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    $CopyIdentity = "{0}\{1}" -f $Database.Name, $ActivateOnServer

    try {

        $TargetCopy = Get-MailboxDatabaseCopyStatus `
            -Identity $CopyIdentity `
            -ErrorAction Stop

    }
    catch {

        Write-Host "`nDatabase copy '$CopyIdentity' was not found." -ForegroundColor Red
        Write-Host "Make sure the target server already hosts a mailbox database copy." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    $CurrentActiveServer = $null

    if (
        $Database.PSObject.Properties.Name -contains 'MountedOnServer' -and
        -not [string]::IsNullOrWhiteSpace([string]$Database.MountedOnServer)
    ) {

        $CurrentActiveServer = [string]$Database.MountedOnServer

    }

    if (
        -not [string]::IsNullOrWhiteSpace($CurrentActiveServer) -and
        $CurrentActiveServer -eq $ActivateOnServer
    ) {

        Write-Host "`nDatabase '$($Database.Name)' is already active on '$ActivateOnServer'." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Move Database Copy               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $Database.Name)

    if ([string]::IsNullOrWhiteSpace($CurrentActiveServer)) {
        $DisplayCurrentServer = "Unknown"
    }
    else {
        $DisplayCurrentServer = $CurrentActiveServer
    }

    Write-Host ("|  Current  : {0,-33}|" -f $DisplayCurrentServer)
    Write-Host ("|  Target   : {0,-33}|" -f $ActivateOnServer)
    Write-Host ("|  Target Status : {0,-28}|" -f $TargetCopy.Status)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nMOVE CONFIGURATION" -ForegroundColor DarkCyan

    if ([string]::IsNullOrWhiteSpace($MountDialOverride)) {
        Write-Host "Mount Dial Override : Default"
    }
    else {
        Write-Host ("Mount Dial Override : {0}" -f $MountDialOverride)
    }

    if ([string]::IsNullOrWhiteSpace($MoveComment)) {
        Write-Host "Move Comment        : None"
    }
    else {
        Write-Host ("Move Comment        : {0}" -f $MoveComment)
    }

    Write-Host ("Skip Active Checks  : {0}" -f $SkipActiveCopyChecks.IsPresent)
    Write-Host ("Skip Client Checks  : {0}" -f $SkipClientExperienceChecks.IsPresent)
    Write-Host ("Skip CPU Checks     : {0}" -f $SkipCpuChecks.IsPresent)
    Write-Host ("Skip Health Checks  : {0}" -f $SkipHealthChecks.IsPresent)
    Write-Host ("Skip Lag Checks     : {0}" -f $SkipLagChecks.IsPresent)
    Write-Host ("Skip Max DB Checks  : {0}" -f $SkipMaximumActiveDatabasesChecks.IsPresent)
    Write-Host ("Skip Move Suppress. : {0}" -f $SkipMoveSuppressionChecks.IsPresent)
    Write-Host ("Terminate Warning   : {0}" -f $TerminateOnWarning.IsPresent)
    Write-Host ("Skip All Checks     : {0}" -f $SkipAllChecks.IsPresent)

    if ($WhatIf) {

        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow

    }

    Write-Host ""
    Write-Host "WARNING" -ForegroundColor Red
    Write-Host "This operation will perform a database switchover." -ForegroundColor Yellow
    Write-Host "The target copy must be suitable for activation." -ForegroundColor Yellow

    if ($MountDialOverride -eq 'BestEffort') {

        Write-Host ""
        Write-Host "WARNING: BestEffort may allow activation with log loss." -ForegroundColor Red

    }

    if ($SkipAllChecks) {

        Write-Host ""
        Write-Host "WARNING: ALL SAFETY CHECKS WILL BE SKIPPED." -ForegroundColor Red

    }

    Write-Host ""

    $Confirmation = Read-Host "Activate '$($Database.Name)' on '$ActivateOnServer'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nMoving active mailbox database..." -ForegroundColor Yellow

        $MoveParameters = @{
            Identity         = $Database.Identity
            ActivateOnServer = $ActivateOnServer
            Confirm          = $false
            ErrorAction      = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($MountDialOverride)) {
            $MoveParameters['MountDialOverride'] = $MountDialOverride
        }

        if (-not [string]::IsNullOrWhiteSpace($MoveComment)) {
            $MoveParameters['MoveComment'] = $MoveComment
        }

        if ($SkipAllChecks) {

            $MoveParameters['SkipAllChecks'] = $true

        }
        else {

            if ($SkipActiveCopyChecks) {
                $MoveParameters['SkipActiveCopyChecks'] = $true
            }

            if ($SkipClientExperienceChecks) {
                $MoveParameters['SkipClientExperienceChecks'] = $true
            }

            if ($SkipCpuChecks) {
                $MoveParameters['SkipCpuChecks'] = $true
            }

            if ($SkipHealthChecks) {
                $MoveParameters['SkipHealthChecks'] = $true
            }

            if ($SkipLagChecks) {
                $MoveParameters['SkipLagChecks'] = $true
            }

            if ($SkipMaximumActiveDatabasesChecks) {
                $MoveParameters['SkipMaximumActiveDatabasesChecks'] = $true
            }

            if ($SkipMoveSuppressionChecks) {
                $MoveParameters['SkipMoveSuppressionChecks'] = $true
            }

        }

        if ($TerminateOnWarning) {
            $MoveParameters['TerminateOnWarning'] = $true
        }

        if ($WhatIf) {
            $MoveParameters['WhatIf'] = $true
        }

        Move-ActiveMailboxDatabase @MoveParameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nDatabase switchover command completed successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to move active mailbox database '$($Database.Name)'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying active database copy..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -Status `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "VERIFICATION" -ForegroundColor DarkCyan

        Write-Host ("Database        : {0}" -f $Verification.Name)
        Write-Host ("Active Server   : {0}" -f $Verification.MountedOnServer)
        Write-Host ("Target Server   : {0}" -f $ActivateOnServer)

        $VerificationCopy = Get-MailboxDatabaseCopyStatus `
            -Identity $CopyIdentity `
            -ErrorAction Stop

        Write-Host ("Target Status   : {0}" -f $VerificationCopy.Status)
        Write-Host ("Content Index   : {0}" -f $VerificationCopy.ContentIndexState)

        if ($Verification.MountedOnServer -eq $ActivateOnServer) {

            Write-Host "`nDatabase is now ACTIVE on '$ActivateOnServer'." -ForegroundColor Green

        }
        else {

            Write-Host "`nWARNING: Database is not reported as active on the target server." -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host "`nSwitchover completed, but verification could not be completed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}