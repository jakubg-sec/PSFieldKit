function Remove-PSFieldKitExchangeDatabaseCopy {

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

    if (-not (Get-Command Remove-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Remove-MailboxDatabaseCopy' is not available." -ForegroundColor Red
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

    $IsActiveCopy = $false

    try {

        $Database = Get-MailboxDatabase `
            -Identity $DatabaseName `
            -Status `
            -ErrorAction Stop

        if (
            $Database.PSObject.Properties.Name -contains 'MountedOnServer' -and
            -not [string]::IsNullOrWhiteSpace([string]$Database.MountedOnServer)
        ) {

            if ($Database.MountedOnServer -eq $ServerName) {
                $IsActiveCopy = $true
            }

        }

    }
    catch {

        Write-Host "`nUnable to determine whether the copy is active." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Remove Database Copy              |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $DatabaseName)
    Write-Host ("|  Server   : {0,-33}|" -f $ServerName)
    Write-Host ("|  Status   : {0,-33}|" -f $CopyStatus.Status)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($IsActiveCopy) {

        Write-Host "`nERROR: This is the ACTIVE database copy." -ForegroundColor Red
        Write-Host "Remove-MailboxDatabaseCopy cannot remove the active copy." -ForegroundColor Yellow
        Write-Host "Remove all passive copies first, then use Remove-MailboxDatabase if the database itself should be removed." -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    Write-Host "`nWARNING" -ForegroundColor Red
    Write-Host "This operation removes the database copy configuration from Exchange." -ForegroundColor Yellow
    Write-Host "The physical EDB and transaction log files are NOT deleted automatically." -ForegroundColor Yellow

    if ($WhatIf) {

        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow

    }

    Write-Host ""

    $Confirmation = Read-Host "Remove database copy '$Identity'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nRemoving database copy '$Identity'..." -ForegroundColor Yellow

        $RemoveParameters = @{
            Identity    = $Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($WhatIf) {
            $RemoveParameters['WhatIf'] = $true
        }

        Remove-MailboxDatabaseCopy @RemoveParameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No database copy was removed." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nDatabase copy removed successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to remove database copy '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying database copy removal..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction SilentlyContinue

        if ($null -eq $Verification) {

            Write-Host "`nDatabase copy '$Identity' is no longer present." -ForegroundColor Green

        }
        else {

            Write-Host "`nWARNING: Database copy '$Identity' still appears to exist." -ForegroundColor Red

        }

    }
    catch {

        Write-Host "`nDatabase copy was removed, but verification could not be completed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Write-Host ""
    Write-Host "IMPORTANT" -ForegroundColor DarkCyan
    Write-Host "Exchange does not automatically delete the physical database copy files." -ForegroundColor Yellow
    Write-Host "Verify the files on '$ServerName' before removing them manually."

    Read-Host "`nPress Enter to continue" | Out-Null
}