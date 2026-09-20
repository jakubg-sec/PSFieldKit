function Set-PSFieldKitExchangeMailboxQuota {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                 Mailbox Quotas               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Mailbox selected:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host ""

    Write-Host "Current quota configuration:" -ForegroundColor Cyan
    Write-Host "  Database Defaults : $($Mailbox.UseDatabaseQuotaDefaults)"
    Write-Host "  Warning Quota     : $($Mailbox.IssueWarningQuota)"
    Write-Host "  Prohibit Send     : $($Mailbox.ProhibitSendQuota)"
    Write-Host "  Prohibit Send/Recv: $($Mailbox.ProhibitSendReceiveQuota)"
    Write-Host ""

    Write-Host "Select quota mode:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Use database defaults"
    Write-Host "  [2] Set custom mailbox quotas"
    Write-Host "  [0] Back"
    Write-Host ""

    $Mode = Read-Host "Select option"

    switch ($Mode) {
        "1" {
            Write-Host ""
            Write-Host "The mailbox will use the quota settings configured on its database." -ForegroundColor Yellow
            Write-Host ""

            $Confirmation = Read-Host "Type DEFAULTS to continue"

            if ($Confirmation -cne "DEFAULTS") {
                Write-Host ""
                Write-Host "Quota change cancelled." -ForegroundColor Yellow
                return
            }

            try {
                Set-Mailbox -Identity $Mailbox.Identity -UseDatabaseQuotaDefaults $true -ErrorAction Stop

                Write-Host ""
                Write-Host "Database quota defaults enabled successfully." -ForegroundColor Green
            }
            catch {
                Write-Host ""
                Write-Host "Failed to enable database quota defaults." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }

            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        "2" {
        }

        "0" {
            return
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    Write-Host ""
    Write-Host "Enter custom mailbox quotas." -ForegroundColor Cyan
    Write-Host "Examples: 10GB, 25GB, 50GB, Unlimited" -ForegroundColor DarkGray
    Write-Host ""

    $IssueWarningQuota = Read-Host "Issue Warning Quota"
    $ProhibitSendQuota = Read-Host "Prohibit Send Quota"
    $ProhibitSendReceiveQuota = Read-Host "Prohibit Send/Receive Quota"

    if (
        [string]::IsNullOrWhiteSpace($IssueWarningQuota) -or
        [string]::IsNullOrWhiteSpace($ProhibitSendQuota) -or
        [string]::IsNullOrWhiteSpace($ProhibitSendReceiveQuota)
    ) {
        Write-Host ""
        Write-Host "All quota values are required." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $QuotaPattern = '^(Unlimited|[0-9]+(\.[0-9]+)?\s*(B|KB|MB|GB|TB))$'

    if ($IssueWarningQuota -notmatch $QuotaPattern) {
        Write-Host ""
        Write-Host "Invalid Issue Warning Quota format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($ProhibitSendQuota -notmatch $QuotaPattern) {
        Write-Host ""
        Write-Host "Invalid Prohibit Send Quota format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($ProhibitSendReceiveQuota -notmatch $QuotaPattern) {
        Write-Host ""
        Write-Host "Invalid Prohibit Send/Receive Quota format." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "New quota configuration:" -ForegroundColor Cyan
    Write-Host "  Issue Warning       : $IssueWarningQuota"
    Write-Host "  Prohibit Send       : $ProhibitSendQuota"
    Write-Host "  Prohibit Send/Recv  : $ProhibitSendReceiveQuota"
    Write-Host ""

    $Confirmation = Read-Host "Type SET QUOTA to continue"

    if ($Confirmation -cne "SET QUOTA") {
        Write-Host ""
        Write-Host "Quota change cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Set-Mailbox `
            -Identity $Mailbox.Identity `
            -UseDatabaseQuotaDefaults $false `
            -IssueWarningQuota $IssueWarningQuota `
            -ProhibitSendQuota $ProhibitSendQuota `
            -ProhibitSendReceiveQuota $ProhibitSendReceiveQuota `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "Mailbox quotas updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Failed to update mailbox quotas." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}