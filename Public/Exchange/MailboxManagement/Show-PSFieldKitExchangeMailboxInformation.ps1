function Show-PSFieldKitExchangeMailboxInformation {
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

    $MailboxIdentity = Read-Host "Enter mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop

        $Statistics = $null

        try {
            $Statistics = Get-MailboxStatistics -Identity $Mailbox.Identity -ErrorAction Stop
        }
        catch {
            Write-Verbose $_.Exception.Message
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
            Write-Host "|             Mailbox Information              |" -ForegroundColor Cyan
            Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Write-Host "|                                              |"
            Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Write-Host "|                                              |"

            Write-Host "|  GENERAL                                     |" -ForegroundColor DarkCyan
            Write-Host ("|  Name         : {0,-29}|" -f ([string]$Mailbox.DisplayName)) -ForegroundColor White
            Write-Host ("|  Alias        : {0,-29}|" -f ([string]$Mailbox.Alias)) -ForegroundColor White
            Write-Host ("|  Identity     : {0,-29}|" -f ([string]$Mailbox.Identity)) -ForegroundColor White
            Write-Host ("|  RecipientType: {0,-29}|" -f ([string]$Mailbox.RecipientTypeDetails)) -ForegroundColor White
            Write-Host ("|  Database     : {0,-29}|" -f ([string]$Mailbox.Database)) -ForegroundColor White

            Write-Host "|                                              |"
            Write-Host "|  EMAIL                                       |" -ForegroundColor DarkCyan

            $PrimarySmtpAddress = [string]$Mailbox.PrimarySmtpAddress

            Write-Host ("|  Primary SMTP : {0,-29}|" -f $PrimarySmtpAddress) -ForegroundColor White

            if (
                $Mailbox.PSObject.Properties.Name -contains "EmailAddresses" -and
                $null -ne $Mailbox.EmailAddresses
            ) {
                Write-Host ("|  Addresses    : {0,-29}|" -f $Mailbox.EmailAddresses.Count) -ForegroundColor White
            }

            Write-Host "|                                              |"
            Write-Host "|  ACCOUNT                                     |" -ForegroundColor DarkCyan

            Write-Host ("|  UserPrincipal: {0,-29}|" -f ([string]$Mailbox.UserPrincipalName)) -ForegroundColor White

            $AccountDisabled = "Unknown"

            if (
                $Mailbox.PSObject.Properties.Name -contains "AccountDisabled" -and
                $null -ne $Mailbox.AccountDisabled
            ) {
                $AccountDisabled = [string]$Mailbox.AccountDisabled
            }

            Write-Host ("|  Disabled     : {0,-29}|" -f $AccountDisabled) -ForegroundColor White

            Write-Host "|                                              |"
            Write-Host "|  MAILBOX                                     |" -ForegroundColor DarkCyan

            $MailboxSize = "Unavailable"
            $ItemCount = "Unavailable"
            $LastLogon = "Unavailable"

            if ($null -ne $Statistics) {
                if (
                    $Statistics.PSObject.Properties.Name -contains "TotalItemSize" -and
                    $null -ne $Statistics.TotalItemSize
                ) {
                    $MailboxSize = [string]$Statistics.TotalItemSize
                }

                if (
                    $Statistics.PSObject.Properties.Name -contains "ItemCount" -and
                    $null -ne $Statistics.ItemCount
                ) {
                    $ItemCount = [string]$Statistics.ItemCount
                }

                if (
                    $Statistics.PSObject.Properties.Name -contains "LastLogonTime" -and
                    $null -ne $Statistics.LastLogonTime
                ) {
                    $LastLogon = [string]$Statistics.LastLogonTime
                }
            }

            Write-Host ("|  Size         : {0,-29}|" -f $MailboxSize) -ForegroundColor White
            Write-Host ("|  Items        : {0,-29}|" -f $ItemCount) -ForegroundColor White
            Write-Host ("|  Last Logon   : {0,-29}|" -f $LastLogon) -ForegroundColor White

            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Write-Host "|                                              |"
            Write-Host "|  [R] Refresh                                 |"
            Write-Host "|  [0] Back                                    |"
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

            $Choice = Read-Host "`nSelect option"

            switch ($Choice) {
                "R" {
                    $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop

                    try {
                        $Statistics = Get-MailboxStatistics -Identity $Mailbox.Identity -ErrorAction Stop
                    }
                    catch {
                        $Statistics = $null
                    }
                }

                "r" {
                    $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop

                    try {
                        $Statistics = Get-MailboxStatistics -Identity $Mailbox.Identity -ErrorAction Stop
                    }
                    catch {
                        $Statistics = $null
                    }
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
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve mailbox information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }
}