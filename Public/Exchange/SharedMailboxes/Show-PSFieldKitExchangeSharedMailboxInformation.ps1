function Show-PSFieldKitExchangeSharedMailboxInformation {
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

    while ($true) {
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
        Write-Host "|          Shared Mailbox Information          |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        $MailboxIdentity = Read-Host "Enter shared mailbox identity"

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

        if ($Mailbox.RecipientTypeDetails -ne "SharedMailbox") {
            Write-Host ""
            Write-Host "The selected object is not a shared mailbox." -ForegroundColor Red
            Write-Host "Current type: $($Mailbox.RecipientTypeDetails)" -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            $MailboxStatistics = Get-MailboxStatistics -Identity $Mailbox.Identity -ErrorAction Stop
        }
        catch {
            $MailboxStatistics = $null
        }

        Write-Host ""
        Write-Host "GENERAL" -ForegroundColor DarkCyan
        Write-Host "  Name              : $($Mailbox.DisplayName)"
        Write-Host "  Alias             : $($Mailbox.Alias)"
        Write-Host "  Identity          : $($Mailbox.Identity)"
        Write-Host "  Recipient Type    : $($Mailbox.RecipientTypeDetails)"
        Write-Host "  Database          : $($Mailbox.Database)"
        Write-Host ""

        Write-Host "EMAIL" -ForegroundColor DarkCyan
        Write-Host "  Primary SMTP      : $($Mailbox.PrimarySmtpAddress)"
        Write-Host "  Email Addresses   : $(@($Mailbox.EmailAddresses).Count)"
        Write-Host ""

        Write-Host "CONFIGURATION" -ForegroundColor DarkCyan
        Write-Host "  Hidden from GAL   : $($Mailbox.HiddenFromAddressListsEnabled)"
        Write-Host "  Database Quotas   : $($Mailbox.UseDatabaseQuotaDefaults)"

        if ($Mailbox.UseDatabaseQuotaDefaults) {
            Write-Host "  Issue Warning     : Database Default"
            Write-Host "  Prohibit Send     : Database Default"
            Write-Host "  Prohibit Send/Recv: Database Default"
        }
        else {
            Write-Host "  Issue Warning     : $($Mailbox.IssueWarningQuota)"
            Write-Host "  Prohibit Send     : $($Mailbox.ProhibitSendQuota)"
            Write-Host "  Prohibit Send/Recv: $($Mailbox.ProhibitSendReceiveQuota)"
        }

        Write-Host ""

        if ($null -ne $MailboxStatistics) {
            Write-Host "MAILBOX STATISTICS" -ForegroundColor DarkCyan
            Write-Host "  Mailbox Size      : $($MailboxStatistics.TotalItemSize)"
            Write-Host "  Item Count        : $($MailboxStatistics.ItemCount)"
            Write-Host "  Deleted Items     : $($MailboxStatistics.DeletedItemCount)"
            Write-Host "  Storage Status    : $($MailboxStatistics.StorageLimitStatus)"
            Write-Host "  Last Logon        : $($MailboxStatistics.LastLogonTime)"
            Write-Host "  Last Logoff       : $($MailboxStatistics.LastLogoffTime)"
            Write-Host ""
        }

        Write-Host "[R] Refresh   [0] Back" -ForegroundColor DarkGray

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "R" {
                continue
            }

            "r" {
                continue
            }

            "0" {
                return
            }

            default {
                Write-Host ""
                Write-Host "Invalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}