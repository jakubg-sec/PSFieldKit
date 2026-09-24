function Set-PSFieldKitExchangeDatabaseProvisioningSuspension {
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

    $SetMailboxDatabaseCommand = Get-Command Set-MailboxDatabase -ErrorAction SilentlyContinue
    if ($SetMailboxDatabaseCommand.Parameters.Keys -notcontains 'IsSuspendedFromProvisioning') {
        Write-Host "`nThe current Exchange version does not expose 'IsSuspendedFromProvisioning'." -ForegroundColor Red
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

    if ($Database.PSObject.Properties.Name -notcontains 'IsSuspendedFromProvisioning') {
        Write-Host "`nThe database does not expose 'IsSuspendedFromProvisioning'." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $CurrentValue = [bool]$Database.IsSuspendedFromProvisioning

    $CurrentReason = if (
        $Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason' -and
        -not [string]::IsNullOrWhiteSpace([string]$Database.IsExcludedFromProvisioningReason)
    ) {
        [string]$Database.IsExcludedFromProvisioningReason
    }
    else {
        "None"
    }

    $CurrentOperator = if (
        $Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningBy' -and
        -not [string]::IsNullOrWhiteSpace([string]$Database.IsExcludedFromProvisioningBy)
    ) {
        [string]$Database.IsExcludedFromProvisioningBy
    }
    else {
        "None"
    }

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Provisioning Suspension                |" -ForegroundColor Cyan
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

    $CurrentStatus = if ($CurrentValue) {
        "Suspended"
    }
    else {
        "Active"
    }

    Write-Host ("Provisioning Status : {0}" -f $CurrentStatus)
    Write-Host ("Reason              : {0}" -f $CurrentReason)
    Write-Host ("Suspended By        : {0}" -f $CurrentOperator)

    Write-Host "`nPROVISIONING ACTION" -ForegroundColor DarkCyan
    Write-Host "[1] Resume provisioning"
    Write-Host "[2] Suspend provisioning"
    Write-Host "[0] Cancel"

    $Selection = Read-Host "`nSelect option"

    if ($Selection -eq '0') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    if ($Selection -notmatch '^[12]$') {
        Write-Host "`nInvalid option." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $NewValue = $Selection -eq '2'

    if ($NewValue -eq $CurrentValue) {
        if ($NewValue) {
            Write-Host "`nProvisioning is already suspended for this database." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nProvisioning is already active for this database." -ForegroundColor Yellow
        }
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $Reason = $CurrentReason

    if ($NewValue) {
        Write-Host "`nSUSPENSION REASON" -ForegroundColor DarkCyan
        Write-Host "The reason must contain at least 10 characters."
        if ($CurrentReason -ne "None") {
            Write-Host "[Enter] Keep current reason: $CurrentReason"
        }

        $ReasonInput = Read-Host "Enter reason"

        if (-not [string]::IsNullOrWhiteSpace($ReasonInput)) {
            $Reason = $ReasonInput.Trim()
        }

        if ([string]::IsNullOrWhiteSpace($Reason) -or $Reason -eq "None" -or $Reason.Length -lt 10) {
            Write-Host "`nThe provisioning suspension reason must contain at least 10 characters." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan

    $NewStatus = if ($NewValue) {
        "Suspended"
    }
    else {
        "Active"
    }

    Write-Host ("Current : {0}" -f $CurrentStatus)
    Write-Host ("New     : {0}" -f $NewStatus)

    if ($NewValue) {
        Write-Host ("Reason  : {0}" -f $Reason)
    }

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Apply provisioning suspension change? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating provisioning suspension..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                    = $Database.Identity
            IsSuspendedFromProvisioning = $NewValue
            Confirm                     = $false
            ErrorAction                 = 'Stop'
        }

        if (
            $NewValue -and
            ($SetMailboxDatabaseCommand.Parameters.Keys -contains 'IsExcludedFromProvisioningReason')
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

        Write-Host "`nProvisioning suspension updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update provisioning suspension." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan

        $VerificationStatus = if ($Verification.IsSuspendedFromProvisioning) {
            "Suspended"
        }
        else {
            "Active"
        }

        Write-Host ("Provisioning Status : {0}" -f $VerificationStatus)

        if ($Verification.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason') {
            $VerificationReason = if (
                [string]::IsNullOrWhiteSpace([string]$Verification.IsExcludedFromProvisioningReason)
            ) {
                "None"
            }
            else {
                [string]$Verification.IsExcludedFromProvisioningReason
            }

            Write-Host ("Reason              : {0}" -f $VerificationReason)
        }

        if ([bool]$Verification.IsSuspendedFromProvisioning -eq $NewValue) {
            Write-Host "`nProvisioning suspension was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned provisioning state does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nProvisioning suspension was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}