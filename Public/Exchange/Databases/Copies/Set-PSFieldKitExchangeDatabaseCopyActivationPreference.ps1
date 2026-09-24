function Set-PSFieldKitExchangeDatabaseCopyActivationPreference {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$ActivationPreference,

        [Parameter()]
        [switch]$WhatIf

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Set-MailboxDatabaseCopy -ErrorAction SilentlyContinue)) {

        Write-Host "`nExchange cmdlet 'Set-MailboxDatabaseCopy' is not available." -ForegroundColor Red
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

    if ($Identity -notmatch '^[^\\]+\\[^\\]+$') {

        Write-Host "`nInvalid database copy identity." -ForegroundColor Red
        Write-Host "Use the following format: DatabaseName\ServerName" -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    if ($ActivationPreference -le 0) {

        Write-Host "`nActivation preference must be greater than or equal to 1." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    $IdentityParts = $Identity.Split('\', 2)

    $DatabaseName = $IdentityParts[0]
    $ServerName = $IdentityParts[1]

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

    try {

        $AllCopies = @(
            Get-MailboxDatabaseCopyStatus `
                -Identity $DatabaseName `
                -ErrorAction Stop
        )

    }
    catch {

        Write-Host "`nUnable to retrieve all database copies for '$DatabaseName'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    $CopyCount = $AllCopies.Count

    if ($ActivationPreference -gt $CopyCount) {

        Write-Host "`nInvalid activation preference." -ForegroundColor Red
        Write-Host "Database '$DatabaseName' has $CopyCount database copy/copies." -ForegroundColor Yellow
        Write-Host "Activation preference cannot be greater than $CopyCount." -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    $CurrentPreference = $null

    if ($CopyStatus.PSObject.Properties.Name -contains 'ActivationPreference') {

        $CurrentPreference = $CopyStatus.ActivationPreference

    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Set Activation Preference              |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    Write-Host ("|  Database : {0,-33}|" -f $DatabaseName)
    Write-Host ("|  Server   : {0,-33}|" -f $ServerName)

    if ($null -ne $CurrentPreference) {

        Write-Host ("|  Current  : {0,-33}|" -f $CurrentPreference)

    }
    else {

        Write-Host "|  Current  : Unknown                         |"

    }

    Write-Host ("|  New      : {0,-33}|" -f $ActivationPreference)
    Write-Host ("|  Copies   : {0,-33}|" -f $CopyCount)

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nACTIVATION PREFERENCE" -ForegroundColor DarkCyan

    Write-Host "Lower values have higher activation priority." -ForegroundColor Yellow
    Write-Host "Value 1 is the highest activation preference." -ForegroundColor Yellow

    Write-Host ""

    Write-Host "CURRENT DATABASE COPIES" -ForegroundColor DarkCyan
    Write-Host ""

    $AllCopies |
        Select-Object `
            @{Name = 'Server'; Expression = {

                if ($_.PSObject.Properties.Name -contains 'MailboxServerName') {

                    $_.MailboxServerName

                }
                else {

                    $_.Identity.ToString().Split('\')[-1]

                }

            }},
            Status,
            ActivationPreference |
        Sort-Object ActivationPreference |
        Format-Table -AutoSize |
        Out-Host

    if (
        $null -ne $CurrentPreference -and
        [int]$CurrentPreference -eq $ActivationPreference
    ) {

        Write-Host "`nThe database copy already has activation preference $ActivationPreference." -ForegroundColor Yellow

        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    if ($WhatIf) {

        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow

    }

    Write-Host ""

    $Confirmation = Read-Host "Set activation preference of '$Identity' to $ActivationPreference? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {

        Write-Host "`nOperation cancelled." -ForegroundColor Yellow

        Read-Host "Press Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nSetting activation preference..." -ForegroundColor Yellow

        $Parameters = @{
            Identity             = $Identity
            ActivationPreference = $ActivationPreference
            Confirm              = $false
            ErrorAction          = 'Stop'
        }

        if ($WhatIf) {

            $Parameters['WhatIf'] = $true

        }

        Set-MailboxDatabaseCopy @Parameters

        if ($WhatIf) {

            Write-Host "`nWhatIf completed. No changes were made." -ForegroundColor Yellow

            Read-Host "`nPress Enter to continue" | Out-Null
            return

        }

        Write-Host "`nActivation preference updated successfully." -ForegroundColor Green

    }
    catch {

        Write-Host "`nFailed to set activation preference for '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Read-Host "`nPress Enter to continue" | Out-Null
        return

    }

    try {

        Write-Host "`nVerifying activation preference..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabaseCopyStatus `
            -Identity $Identity `
            -ErrorAction Stop

        Write-Host ""

        Write-Host "VERIFICATION" -ForegroundColor DarkCyan

        Write-Host ("Database             : {0}" -f $DatabaseName)
        Write-Host ("Server               : {0}" -f $ServerName)
        Write-Host ("Activation Preference: {0}" -f $Verification.ActivationPreference)
        Write-Host ("Status               : {0}" -f $Verification.Status)

        if ([int]$Verification.ActivationPreference -eq $ActivationPreference) {

            Write-Host "`nActivation preference was updated successfully." -ForegroundColor Green

        }
        else {

            Write-Host "`nWARNING: The returned activation preference does not match the requested value." -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host "`nActivation preference was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow

    }

    Read-Host "`nPress Enter to continue" | Out-Null
}