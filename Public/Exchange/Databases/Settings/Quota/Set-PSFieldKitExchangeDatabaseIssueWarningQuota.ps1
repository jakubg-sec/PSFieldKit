function Set-PSFieldKitExchangeDatabaseIssueWarningQuota {
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

    $CurrentQuota = [string]$Database.IssueWarningQuota
    $MaximumQuota = [string]$Database.ProhibitSendReceiveQuota

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Issue Warning Quota                 |" -ForegroundColor Cyan
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
    Write-Host ("Issue Warning Quota   : {0}" -f $CurrentQuota)
    Write-Host ("Prohibit Send/Receive : {0}" -f $MaximumQuota)

    Write-Host "`nNEW ISSUE WARNING QUOTA" -ForegroundColor DarkCyan
    Write-Host "Examples: 1GB, 2 GB, 500MB, 1.5TB, unlimited"
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
        $NewQuotaBytes = $null
    }
    else {
        $NormalizedQuota = $QuotaInput -replace '(?i)(\d)\s*(B|KB|MB|GB|TB)$', '$1 $2'

        try {
            $ParsedQuota = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse($NormalizedQuota)
            $NewQuota = $ParsedQuota
            $NewQuotaBytes = $ParsedQuota.ToBytes()
        }
        catch {
            Write-Host "`nInvalid quota value '$QuotaInput'." -ForegroundColor Red
            Write-Host "Use values such as 1GB, 2 GB, 500MB, 1.5TB or unlimited." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }

        if ($NewQuotaBytes -gt 2199023254528) {
            Write-Host "`nThe quota exceeds the maximum supported value of 1.999999999 TB." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
    }

    if ($NewQuota -eq 'unlimited') {
        if ($MaximumQuota -ne 'unlimited') {
            Write-Host "`nIssue Warning Quota cannot be unlimited while Prohibit Send/Receive Quota is '$MaximumQuota'." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
    }
    else {
        try {
            if ($MaximumQuota -ne 'unlimited') {
                $MaximumQuotaBytes = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse(
                    ($MaximumQuota -replace '(?i)(\d)\s*(B|KB|MB|GB|TB)', '$1 $2')
                ).ToBytes()

                if ($NewQuotaBytes -gt $MaximumQuotaBytes) {
                    Write-Host "`nIssue Warning Quota cannot be greater than Prohibit Send/Receive Quota." -ForegroundColor Red
                    Write-Host ("Maximum allowed: {0}" -f $MaximumQuota) -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                    return
                }
            }
        }
        catch {
            Write-Host "`nUnable to validate the quota relationship." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }
    }

    $CurrentQuotaBytes = $null

    if ($CurrentQuota -ne 'unlimited') {
        try {
            $CurrentQuotaBytes = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse(
                ($CurrentQuota -replace '(?i)(\d)\s*(B|KB|MB|GB|TB)', '$1 $2')
            ).ToBytes()
        }
        catch {
            $CurrentQuotaBytes = $null
        }
    }

    if (
        ($NewQuota -eq 'unlimited' -and $CurrentQuota -eq 'unlimited') -or
        ($null -ne $CurrentQuotaBytes -and $NewQuotaBytes -eq $CurrentQuotaBytes)
    ) {
        Write-Host "`nThe database already has Issue Warning Quota set to '$CurrentQuota'." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    $NewQuotaDisplay = if ($NewQuota -eq 'unlimited') {
        "unlimited"
    }
    else {
        $NewQuota.ToString()
    }

    Write-Host "`nCHANGE" -ForegroundColor DarkCyan
    Write-Host ("Current : {0}" -f $CurrentQuota)
    Write-Host ("New     : {0}" -f $NewQuotaDisplay)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""
    $Confirmation = Read-Host "Set Issue Warning Quota to '$NewQuotaDisplay'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating Issue Warning Quota..." -ForegroundColor Yellow

        $Parameters = @{
            Identity          = $Database.Identity
            IssueWarningQuota = $NewQuota
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

        Write-Host "`nIssue Warning Quota updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update Issue Warning Quota." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    try {
        $Verification = Get-MailboxDatabase -Identity $Database.Identity -ErrorAction Stop

        Write-Host "`nVERIFICATION" -ForegroundColor DarkCyan
        Write-Host ("Issue Warning Quota   : {0}" -f $Verification.IssueWarningQuota)
        Write-Host ("Prohibit Send/Receive : {0}" -f $Verification.ProhibitSendReceiveQuota)

        if ($NewQuota -eq 'unlimited') {
            $VerificationMatches = [string]$Verification.IssueWarningQuota -eq 'Unlimited'
        }
        else {
            $VerificationQuota = [Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse(
                ([string]$Verification.IssueWarningQuota -replace '(?i)(\d)\s*(B|KB|MB|GB|TB)', '$1 $2')
            )

            $VerificationMatches = $VerificationQuota.ToBytes() -eq $NewQuotaBytes
        }

        if ($VerificationMatches) {
            Write-Host "`nIssue Warning Quota was updated successfully." -ForegroundColor Green
        }
        else {
            Write-Host "`nWARNING: The returned quota does not match the requested value." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nIssue Warning Quota was changed, but verification failed." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
        Start-Sleep -Seconds 2
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}