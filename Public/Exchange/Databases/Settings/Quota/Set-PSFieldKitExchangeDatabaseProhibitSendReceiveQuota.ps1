function Set-PSFieldKitExchangeDatabaseProhibitSendReceiveQuota {
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

    $CurrentQuota = [string]$Database.ProhibitSendReceiveQuota
    $IssueWarningQuota = [string]$Database.IssueWarningQuota
    $ProhibitSendQuota = [string]$Database.ProhibitSendQuota

    $CurrentQuotaIsUnlimited = $Database.ProhibitSendReceiveQuota.IsUnlimited
    $IssueWarningQuotaIsUnlimited = $Database.IssueWarningQuota.IsUnlimited
    $ProhibitSendQuotaIsUnlimited = $Database.ProhibitSendQuota.IsUnlimited

    $CurrentQuotaBytes = $null
    $IssueWarningQuotaBytes = $null
    $ProhibitSendQuotaBytes = $null

    if (-not $CurrentQuotaIsUnlimited) {
        $CurrentQuotaBytes = $Database.ProhibitSendReceiveQuota.Value.ToBytes()
    }

    if (-not $IssueWarningQuotaIsUnlimited) {
        $IssueWarningQuotaBytes = $Database.IssueWarningQuota.Value.ToBytes()
    }

    if (-not $ProhibitSendQuotaIsUnlimited) {
        $ProhibitSendQuotaBytes = $Database.ProhibitSendQuota.Value.ToBytes()
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Prohibit Send/Receive Quota         |" -ForegroundColor Cyan
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
    Write-Host ("Issue Warning Quota       : {0}" -f $IssueWarningQuota)
    Write-Host ("Prohibit Send Quota       : {0}" -f $ProhibitSendQuota)
    Write-Host ("Prohibit Send/Receive     : {0}" -f $CurrentQuota)

    Write-Host "`nNEW PROHIBIT SEND/RECEIVE QUOTA" -ForegroundColor DarkCyan
    Write-Host "Examples: 1GB, 2GB, 2 GB, 500MB, 1.5TB, unlimited"
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
            Write-Host "Use values such as 1GB, 2GB, 2 GB, 500MB, 1.5TB or unlimited." -ForegroundColor Yellow
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
            Write-Host "Use values such as 1GB, 2GB, 2 GB, 500MB, 1.5TB or unlimited." -ForegroundColor Yellow
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
        if (-not $IssueWarningQuotaIsUnlimited -or -not $ProhibitSendQuotaIsUnlimited) {
            Write-Host "`nProhibit Send/Receive Quota cannot be unlimited while lower quotas are finite." -ForegroundColor Red
            Write-Host "Issue Warning Quota : $IssueWarningQuota" -ForegroundColor Yellow
            Write-Host "Prohibit Send Quota : $ProhibitSendQuota" -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }
    else {
        if ($IssueWarningQuotaIsUnlimited) {
            Write-Host "`nProhibit Send/Receive Quota cannot be finite while Issue Warning Quota is unlimited." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($ProhibitSendQuotaIsUnlimited) {
            Write-Host "`nProhibit Send/Receive Quota cannot be finite while Prohibit Send Quota is unlimited." -ForegroundColor Red
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($NewQuotaBytes -lt $IssueWarningQuotaBytes) {
            Write-Host "`nProhibit Send/Receive Quota cannot be lower than Issue Warning Quota." -ForegroundColor Red
            Write-Host ("Minimum allowed: {0}" -f $IssueWarningQuota) -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }

        if ($NewQuotaBytes -lt $ProhibitSendQuotaBytes) {
            Write-Host "`nProhibit Send/Receive Quota cannot be lower than Prohibit Send Quota." -ForegroundColor Red
            Write-Host ("Minimum allowed: {0}" -f $ProhibitSendQuota) -ForegroundColor Yellow
            Read-Host "Press Enter to continue" | Out-Null
            return
        }
    }

    if (
        ($NewQuotaIsUnlimited -and $CurrentQuotaIsUnlimited) -or
        (-not $NewQuotaIsUnlimited -and -not $CurrentQuotaIsUnlimited -and $NewQuotaBytes -eq $CurrentQuotaBytes)
    ) {
        Write-Host "`nThe database already has Prohibit Send/Receive Quota set to '$CurrentQuota'." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current : {0}" -f $CurrentQuota)
    Write-Host ("New     : {0}" -f $NewQuota)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Set Prohibit Send/Receive Quota to '$NewQuota'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Prohibit Send/Receive Quota..." -ForegroundColor Yellow

        $Parameters = @{
            Identity                 = $Database.Identity
            ProhibitSendReceiveQuota = $NewQuota
            Confirm                  = $false
            ErrorAction              = 'Stop'
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

        Write-Host "`nProhibit Send/Receive Quota updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Prohibit Send/Receive Quota." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Issue Warning Quota       : {0}" -f $Verification.IssueWarningQuota)
        Write-Host ("Prohibit Send Quota       : {0}" -f $Verification.ProhibitSendQuota)
        Write-Host ("Prohibit Send/Receive     : {0}" -f $Verification.ProhibitSendReceiveQuota)

        $VerificationIsUnlimited = $Verification.ProhibitSendReceiveQuota.IsUnlimited
        $VerificationMatches = $false

        if ($NewQuotaIsUnlimited) {
            $VerificationMatches = $VerificationIsUnlimited
        }
        elseif (-not $VerificationIsUnlimited) {
            $VerificationBytes = $Verification.ProhibitSendReceiveQuota.Value.ToBytes()
            $VerificationMatches = $VerificationBytes -eq $NewQuotaBytes
        }

        if ($VerificationMatches) {
            Write-Host "`nProhibit Send/Receive Quota was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned quota does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nProhibit Send/Receive Quota was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Read-Host "Press Enter to continue" | Out-Null
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}