function Set-PSFieldKitExchangeDatabaseProvisioning {
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
        $Database = Get-MailboxDatabase -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentValue = [bool]$Database.IsExcludedFromProvisioning
    $CurrentReason = if (
        $Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason' -and
        -not [string]::IsNullOrWhiteSpace([string]$Database.IsExcludedFromProvisioningReason)
    ) {
        [string]$Database.IsExcludedFromProvisioningReason
    }
    else {
        "None"
    }

    $ExcludedByOperator = if ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningByOperator') {
        [bool]$Database.IsExcludedFromProvisioningByOperator
    }
    else {
        $false
    }

    $ExcludedDueToCorruption = if ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningDueToLogicalCorruption') {
        [bool]$Database.IsExcludedFromProvisioningDueToLogicalCorruption
    }
    else {
        $false
    }

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Mailbox Provisioning                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 33) {
        $DisplayName = $DisplayName.Substring(0, 30) + "..."
    }
    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nCURRENT SETTINGS" -ForegroundColor DarkCyan
    Write-Host ("Excluded From Provisioning       : {0}" -f $CurrentValue)
    Write-Host ("Exclusion Reason                 : {0}" -f $CurrentReason)
    Write-Host ("Excluded By Operator             : {0}" -f $ExcludedByOperator)
    Write-Host ("Excluded Due To Logical Corruption: {0}" -f $ExcludedDueToCorruption)

    Write-Host "`nPROVISIONING ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Enable mailbox provisioning"
    Write-Host "[2] Exclude database from provisioning"
    Write-Host "[0] Cancel"

    do {
        $Selection = Read-Host "`nSelect option"
    }
    while ($Selection -notmatch '^[012]$')

    if ($Selection -eq '0') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    $NewValue = $Selection -eq '2'

    if ($NewValue -eq $CurrentValue) {
        if ($NewValue) {
            Write-Host "`nMailbox provisioning is already disabled for this database." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nMailbox provisioning is already enabled for this database." -ForegroundColor Yellow
        }
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not $NewValue -and $ExcludedDueToCorruption) {
        Write-Host "`nThis database is excluded from provisioning because of logical corruption." -ForegroundColor Red
        Write-Host "Fix the corruption condition before re-enabling provisioning." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $Reason = $CurrentReason

    if ($NewValue) {
        if (
            $Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason'
        ) {
            Write-Host "`nEXCLUSION REASON" -ForegroundColor DarkCyan
            Write-Host "Exchange Server 2016/2019/SE requires at least 10 characters."
            Write-Host "[Enter] Keep current reason: $CurrentReason"

            $ReasonInput = Read-Host "Enter reason"

            if (-not [string]::IsNullOrWhiteSpace($ReasonInput)) {
                $Reason = $ReasonInput.Trim()
            }

            if ([string]::IsNullOrWhiteSpace($Reason) -or $Reason.Length -lt 10 -or $Reason -eq "None") {
                Write-Host "`nThe exclusion reason must contain at least 10 characters." -ForegroundColor Red
                Read-Host "Press Enter to continue" | Out-Null
                return
            }
        }
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current provisioning : {0}" -f $(if ($CurrentValue) { "Excluded" } else { "Enabled" }))
    Write-Host ("New provisioning     : {0}" -f $(if ($NewValue) { "Excluded" } else { "Enabled" }))

    if ($NewValue) {
        Write-Host ("Reason               : {0}" -f $Reason)
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply provisioning change? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating mailbox provisioning..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                  = $Database.Identity
            IsExcludedFromProvisioning = $NewValue
            Confirm                   = $false
            ErrorAction               = 'Stop'
        }

        if (
            $NewValue -and
            ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason')
        ) {
            $Parameters['IsExcludedFromProvisioningReason'] = $Reason
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

        Write-Host "`nMailbox provisioning updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update mailbox provisioning." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Excluded From Provisioning : {0}" -f $Verification.IsExcludedFromProvisioning)

        if ($Verification.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason') {
            $VerificationReason = if (
                [string]::IsNullOrWhiteSpace([string]$Verification.IsExcludedFromProvisioningReason)
            ) {
                "None"
            }
            else {
                [string]$Verification.IsExcludedFromProvisioningReason
            }

            Write-Host ("Exclusion Reason           : {0}" -f $VerificationReason)
        }

        if ([bool]$Verification.IsExcludedFromProvisioning -eq $NewValue) {
            Write-Host "`nMailbox provisioning was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned provisioning state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nProvisioning was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}