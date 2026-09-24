function Set-PSFieldKitExchangeDatabaseRecoverableItemsWarningQuota {
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

    $CurrentQuota = [string]$Database.RecoverableItemsWarningQuota
    $RecoverableItemsQuota = [string]$Database.RecoverableItemsQuota

    $CurrentQuotaIsUnlimited = $Database.RecoverableItemsWarningQuota.IsUnlimited
    $RecoverableItemsQuotaIsUnlimited = $Database.RecoverableItemsQuota.IsUnlimited

    $CurrentQuotaBytes = $null
    $RecoverableItemsQuotaBytes = $null

    if (-not $CurrentQuotaIsUnlimited) {
        $CurrentQuotaBytes = $Database.RecoverableItemsWarningQuota.Value.ToBytes()
    }

    if (-not $RecoverableItemsQuotaIsUnlimited) {
        $RecoverableItemsQuotaBytes = $Database.RecoverableItemsQuota.Value.ToBytes()
    }

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Recoverable Items Warning Quota        |" -ForegroundColor Cyan
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
    Write-Host ("Recoverable Items Warning : {0}" -f $CurrentQuota)
    Write-Host ("Recoverable Items Quota   : {0}" -f $RecoverableItemsQuota)

    Write-Host "`nNEW RECOVERABLE ITEMS WARNING QUOTA" -ForegroundColor DarkCyan
    Write-Host "Examples: 10GB, 10 GB, 20GB, 500MB, 1TB, unlimited"
    Write-Host "[Enter] Keep current value"

    $QuotaInput = Read-Host "Enter quota"

    if ([string]::IsNullOrWhiteSpace($QuotaInput)) {
        Write-Host "`nNo changes selected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $QuotaInput = $QuotaInput.Trim()

    if ($QuotaInput -ieq 'unlimited') {
        $NewQuota = 'unlimited'
        $NewQuotaIsUnlimited = $true
        $NewQuotaBytes = $null
    }
    else {
        if ($QuotaInput -notmatch '^\s*\d+(?:[.,]\d+)?\s*(B|KB|MB|GB|TB)\s*$') {
            Write-Host "`nInvalid quota value '$QuotaInput'." -ForegroundColor Red
            Write-Host "Use values such as 10GB, 10 GB, 20GB, 500MB, 1TB or unlimited." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        $NormalizedQuota = $QuotaInput -replace ',', '.'
        $NormalizedQuota = $NormalizedQuota -replace '(?i)(\d)\s*(B|KB|MB|GB|TB)\s*$', '$1 $2'

        try {
            $ParsedQuota = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse($NormalizedQuota)
            $NewQuotaBytes = $ParsedQuota.ToBytes()
            $NewQuota = $ParsedQuota.ToString()
            $NewQuotaIsUnlimited = $false
        }
        catch {
            Write-Host "`nInvalid quota value '$QuotaInput'." -ForegroundColor Red
            Write-Host "Use values such as 10GB, 10 GB, 20GB, 500MB, 1TB or unlimited." -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($NewQuotaBytes -gt 2199023254528) {
            Write-Host "`nThe quota exceeds the maximum supported value of 1.999999999 TB." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    if ($NewQuotaIsUnlimited) {
        if (-not $RecoverableItemsQuotaIsUnlimited) {
            Write-Host "`nRecoverable Items Warning Quota cannot be unlimited while Recoverable Items Quota is '$RecoverableItemsQuota'." -ForegroundColor Red
            Write-Host ("Maximum allowed: {0}" -f $RecoverableItemsQuota) -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }
    else {
        if ($RecoverableItemsQuotaIsUnlimited) {
            # Any finite warning quota is valid when the main quota is unlimited.
        }
        elseif ($NewQuotaBytes -gt $RecoverableItemsQuotaBytes) {
            Write-Host "`nRecoverable Items Warning Quota cannot be greater than Recoverable Items Quota." -ForegroundColor Red
            Write-Host ("Maximum allowed: {0}" -f $RecoverableItemsQuota) -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    if (
        ($NewQuotaIsUnlimited -and $CurrentQuotaIsUnlimited) -or
        (-not $NewQuotaIsUnlimited -and -not $CurrentQuotaIsUnlimited -and $NewQuotaBytes -eq $CurrentQuotaBytes)
    ) {
        Write-Host "`nThe database already has Recoverable Items Warning Quota set to '$CurrentQuota'." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current : {0}" -f $CurrentQuota)
    Write-Host ("New     : {0}" -f $NewQuota)
    Write-Host ("Quota   : {0}" -f $RecoverableItemsQuota)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Set Recoverable Items Warning Quota to '$NewQuota'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Recoverable Items Warning Quota..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                    = $Database.Identity
            RecoverableItemsWarningQuota = $NewQuota
            Confirm                     = $false
            ErrorAction                 = 'Stop'
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

        Write-Host "`nRecoverable Items Warning Quota updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Recoverable Items Warning Quota." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Recoverable Items Warning : {0}" -f $Verification.RecoverableItemsWarningQuota)
        Write-Host ("Recoverable Items Quota   : {0}" -f $Verification.RecoverableItemsQuota)

        $VerificationIsUnlimited = $Verification.RecoverableItemsWarningQuota.IsUnlimited
        $VerificationMatches = $false

        if ($NewQuotaIsUnlimited) {
            $VerificationMatches = $VerificationIsUnlimited
        }
        elseif (-not $VerificationIsUnlimited) {
            $VerificationBytes = $Verification.RecoverableItemsWarningQuota.Value.ToBytes()
            $VerificationMatches = $VerificationBytes -eq $NewQuotaBytes
        }

        if ($VerificationMatches) {
            Write-Host "`nRecoverable Items Warning Quota was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned quota does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nRecoverable Items Warning Quota was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}