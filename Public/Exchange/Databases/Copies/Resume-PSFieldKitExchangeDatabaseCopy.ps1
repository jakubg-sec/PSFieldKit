function Resume-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [switch]$ReplicationOnly,

        [Parameter()]
        [switch]$DisableReplayLag,

        [Parameter()]
        [string]$DisableReplayLagReason,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Resume-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Resume-MailboxDatabaseCopy' is not available." -ForegroundColor Red
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

    if (
        $DisableReplayLag -and
        [string]::IsNullOrWhiteSpace($DisableReplayLagReason)
    ) {

        Write-Host "`nDisableReplayLagReason is required when -DisableReplayLag is used." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if (
        -not $DisableReplayLag -and
        -not [string]::IsNullOrWhiteSpace($DisableReplayLagReason)
    ) {

        Write-Host "`nDisableReplayLagReason can only be used together with -DisableReplayLag." -ForegroundColor Yellow
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

    $ActivationSuspended = $null

    if ($CopyStatus.PSObject.Properties.Name -contains 'ActivationSuspended') {
        $ActivationSuspended = $CopyStatus.ActivationSuspended
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Resume Database Copy             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $DatabaseName)
    Write-Host ("|  Server   : {0,-33}|" -f $ServerName)
    Write-Host ("|  Status   : {0,-33}|" -f $CurrentStatus)

    if ($null -ne $ActivationSuspended) {
        Write-Host ("|  Activation Suspended : {0,-20}|" -f $ActivationSuspended)
    }

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nRESUME MODE" -ForegroundColor DarkCyan

    if ($ReplicationOnly) {

        Write-Host "Mode : Replication only" -ForegroundColor Yellow
        Write-Host "Effect: Replication resumes, but activation remains suspended." -ForegroundColor Yellow

    }
    else {

        Write-Host "Mode : Full resume" -ForegroundColor Yellow
        Write-Host "Effect: Replication/replay resumes and activation suspension is cleared." -ForegroundColor Yellow

    }

    if ($DisableReplayLag) {

        Write-Host ""
        Write-Host "Replay lag will be disabled." -ForegroundColor Yellow
        Write-Host ("Reason: {0}" -f $DisableReplayLagReason) -ForegroundColor Yellow

    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Resume database copy '$Identity'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nResuming database copy '$Identity'..." -ForegroundColor Yellow

        $ResumeParameters = @{
            Identity    = $Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($ReplicationOnly) {
            $ResumeParameters['ReplicationOnly'] = $true
        }

        if ($DisableReplayLag) {
            $ResumeParameters['DisableReplayLag'] = $true
            $ResumeParameters['DisableReplayLagReason'] = $DisableReplayLagReason
        }

        if ($WhatIf) {
            $ResumeParameters['WhatIf'] = $true
        }

        Resume-MailboxDatabaseCopy @ResumeParameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nDatabase copy resume command completed successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to resume database copy '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying database copy status..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop

        $VerificationStatus = [string]$Verification.Status

        Write-Host ""
        Write-Host "VERIFICATION" -ForegroundColor DarkCyan

        Write-Host ("Database              : {0}" -f $DatabaseName)
        Write-Host ("Server                : {0}" -f $ServerName)
        Write-Host ("Status                : {0}" -f $VerificationStatus)

        if ($Verification.PSObject.Properties.Name -contains 'ActivationSuspended') {
            Write-Host ("Activation Suspended  : {0}" -f $Verification.ActivationSuspended)
        }

        if ($Verification.PSObject.Properties.Name -contains 'ContentIndexState') {
            Write-Host ("Content Index         : {0}" -f $Verification.ContentIndexState)
        }

        if ($Verification.PSObject.Properties.Name -contains 'CopyQueueLength') {
            Write-Host ("Copy Queue Length     : {0}" -f $Verification.CopyQueueLength)
        }

        if ($Verification.PSObject.Properties.Name -contains 'ReplayQueueLength') {
            Write-Host ("Replay Queue Length   : {0}" -f $Verification.ReplayQueueLength)
        }

        if ($ReplicationOnly) {

            if (
                $Verification.PSObject.Properties.Name -contains 'ActivationSuspended' -and
                $Verification.ActivationSuspended
            ) {

                Write-Host "`nReplication resumed. Activation remains suspended as requested." -ForegroundColor Green

            }
            else {

                Write-Host "`nReplication resume completed. Verify activation state manually if required." -ForegroundColor Yellow

            }

        }
        else {

            if (
                $Verification.PSObject.Properties.Name -contains 'ActivationSuspended' -and
                -not $Verification.ActivationSuspended
            ) {

                Write-Host "`nDatabase copy has been fully resumed." -ForegroundColor Green

            }
            else {

                Write-Host "`nDatabase copy resume completed, but activation may still be suspended." -ForegroundColor Yellow

            }

        }

    }
    catch {

        Write-Host "`nDatabase copy was resumed, but its status could not be verified." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}