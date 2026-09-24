function Set-PSFieldKitExchangeDatabaseProhibitSendQuota {
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
        Start-Sleep -Seconds 2
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    try {
        $Database = Get-MailboxDatabase -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    $CurrentQuota = [string]$Database.ProhibitSendQuota
    $IssueWarningQuota = [string]$Database.IssueWarningQuota
    $ProhibitSendReceiveQuota = [string]$Database.ProhibitSendReceiveQuota

    $CurrentQuotaIsUnlimited = $Database.ProhibitSendQuota.IsUnlimited
    $IssueWarningQuotaIsUnlimited = $Database.IssueWarningQuota.IsUnlimited
    $ProhibitSendReceiveQuotaIsUnlimited = $Database.ProhibitSendReceiveQuota.IsUnlimited

    $CurrentQuotaBytes = $null
    $IssueWarningQuotaBytes = $null
    $ProhibitSendReceiveQuotaBytes = $null

    if (-not $CurrentQuotaIsUnlimited) {
        $CurrentQuotaBytes = $Database.ProhibitSendQuota.Value.ToBytes()
    }

    if (-not $IssueWarningQuotaIsUnlimited) {
        $IssueWarningQuotaBytes = $Database.IssueWarningQuota.Value.ToBytes()
    }

    if (-not $ProhibitSendReceiveQuotaIsUnlimited) {
        $ProhibitSendReceiveQuotaBytes = $Database.ProhibitSendReceiveQuota.Value.ToBytes()
    }

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Prohibit Send Quota               |" -ForegroundColor Cyan
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
    Write-Host ("Prohibit Send Quota       : {0}" -f $CurrentQuota)
    Write-Host ("Prohibit Send/Receive     : {0}" -f $ProhibitSendReceiveQuota)

    Write-Host "`nNEW PROHIBIT SEND QUOTA" -ForegroundColor DarkCyan
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
            Start-Sleep -Seconds 2
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
            Start-Sleep -Seconds 2
            return
        }

        if ($NewQuotaBytes -gt 2199023254528) {
            Write-Host "`nThe quota exceeds the maximum supported value of 1.999999999 TB." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
    }

    if ($NewQuotaIsUnlimited) {
        if (-not $ProhibitSendReceiveQuotaIsUnlimited) {
            Write-Host "`nProhibit Send Quota cannot be unlimited while Prohibit Send/Receive Quota is '$ProhibitSendReceiveQuota'." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
    }
    else {
        if ($IssueWarningQuotaIsUnlimited) {
            Write-Host "`nProhibit Send Quota cannot be finite while Issue Warning Quota is unlimited." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }

        if ($NewQuotaBytes -lt $IssueWarningQuotaBytes) {
            Write-Host "`nProhibit Send Quota cannot be lower than Issue Warning Quota." -ForegroundColor Red
            Write-Host ("Minimum allowed: {0}" -f $IssueWarningQuota) -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }

        if (
            -not $ProhibitSendReceiveQuotaIsUnlimited -and
            $NewQuotaBytes -gt $ProhibitSendReceiveQuotaBytes
        ) {
            Write-Host "`nProhibit Send Quota cannot be greater than Prohibit Send/Receive Quota." -ForegroundColor Red
            Write-Host ("Maximum allowed: {0}" -f $ProhibitSendReceiveQuota) -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }
    }

    if (
        ($NewQuotaIsUnlimited -and $CurrentQuotaIsUnlimited) -or
        (-not $NewQuotaIsUnlimited -and -not $CurrentQuotaIsUnlimited -and $NewQuotaBytes -eq $CurrentQuotaBytes)
    ) {
        Write-Host "`nThe database already has Prohibit Send Quota set to '$CurrentQuota'." -ForegroundColor Yellow
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
    $Confirmation = Read-Host "Set Prohibit Send Quota to '$NewQuota'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Prohibit Send Quota..." -ForegroundColor Yellow

        $Parameters = @{
            Identity          = $Database.Identity
            ProhibitSendQuota = $NewQuota
            Confirm           = $false
            ErrorAction       = 'Stop'
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

        Write-Host "`nProhibit Send Quota updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Prohibit Send Quota." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Issue Warning Quota       : {0}" -f $Verification.IssueWarningQuota)
        Write-Host ("Prohibit Send Quota       : {0}" -f $Verification.ProhibitSendQuota)
        Write-Host ("Prohibit Send/Receive     : {0}" -f $Verification.ProhibitSendReceiveQuota)

        $VerificationIsUnlimited = $Verification.ProhibitSendQuota.IsUnlimited
        $VerificationMatches = $false

        if ($NewQuotaIsUnlimited) {
            $VerificationMatches = $VerificationIsUnlimited
        }
        elseif (-not $VerificationIsUnlimited) {
            $VerificationBytes = $Verification.ProhibitSendQuota.Value.ToBytes()
            $VerificationMatches = $VerificationBytes -eq $NewQuotaBytes
        }

        if ($VerificationMatches) {
            Write-Host "`nProhibit Send Quota was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned quota does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nProhibit Send Quota was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Start-Sleep -Seconds 2
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}