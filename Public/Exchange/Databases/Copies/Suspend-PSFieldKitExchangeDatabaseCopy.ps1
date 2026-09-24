function Suspend-PSFieldKitExchangeDatabaseCopy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [switch]$ActivationOnly,

        [Parameter()]
        [string]$SuspendComment,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Suspend-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Suspend-MailboxDatabaseCopy' is not available." -ForegroundColor Red
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

    if ($SuspendComment.Length -gt 512) {

        Write-Host "`nSuspend comment cannot exceed 512 characters." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Suspend Database Copy             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $DatabaseName)
    Write-Host ("|  Server   : {0,-33}|" -f $ServerName)
    Write-Host ("|  Status   : {0,-33}|" -f $CurrentStatus)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($CurrentStatus -match 'Suspended') {

        Write-Host "`nThis database copy already reports a suspended status." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    Write-Host "`nSUSPENSION MODE" -ForegroundColor DarkCyan

    if ($ActivationOnly) {

        Write-Host "Mode    : Activation only" -ForegroundColor Yellow
        Write-Host "Effect  : Automatic activation of this copy will be suspended."

    }
    else {

        Write-Host "Mode    : Replication and replay" -ForegroundColor Yellow
        Write-Host "Effect  : Log copying and replay activity will be suspended."

    }

    if (-not [string]::IsNullOrWhiteSpace($SuspendComment)) {
        Write-Host ("Comment : {0}" -f $SuspendComment)
    }
    else {
        Write-Host "Comment : None"
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Suspend database copy '$Identity'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nSuspending database copy '$Identity'..." -ForegroundColor Yellow

        $SuspendParameters = @{
            Identity    = $Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($ActivationOnly) {
            $SuspendParameters['ActivationOnly'] = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($SuspendComment)) {
            $SuspendParameters['SuspendComment'] = $SuspendComment
        }

        if ($WhatIf) {
            $SuspendParameters['WhatIf'] = $true
        }

        Suspend-MailboxDatabaseCopy @SuspendParameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nDatabase copy suspension command completed successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to suspend database copy '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying database copy status..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "VERIFICATION" -ForegroundColor DarkCyan

        Write-Host ("Database : {0}" -f $DatabaseName)
        Write-Host ("Server   : {0}" -f $ServerName)
        Write-Host ("Status   : {0}" -f $Verification.Status)

        if (
            $Verification.PSObject.Properties.Name -contains 'ActivationSuspended'
        ) {
            Write-Host ("Activation Suspended : {0}" -f $Verification.ActivationSuspended)
        }

        if ($Verification.Status -match 'Suspended') {

            Write-Host "`nDatabase copy is suspended." -ForegroundColor Green

        }
        elseif ($ActivationOnly) {

            Write-Host "`nActivation suspension was requested." -ForegroundColor Green
            Write-Host "Check the ActivationSuspended property if available." -ForegroundColor Yellow

        }
        else {

            Write-Host "`nWARNING: Exchange did not report a suspended status." -ForegroundColor Yellow
            Write-Host "Current status: $($Verification.Status)" -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host "`nDatabase copy was suspended, but its status could not be verified." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}