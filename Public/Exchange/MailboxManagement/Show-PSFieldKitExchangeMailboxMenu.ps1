function Show-PSFieldKitExchangeMailboxMenu {
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
        Write-Host "|               Mailbox Management             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  MAILBOX MANAGEMENT                          |" -ForegroundColor DarkCyan
        Write-Host "|  [1] List Mailboxes                          |"
        Write-Host "|  [2] Search Mailboxes                        |"
        Write-Host "|  [3] Mailbox Information                     |"
        Write-Host "|  [4] Create Mailbox                          |"
        Write-Host "|  [5] Disable Mailbox                         |"
        Write-Host "|  [6] Enable Mailbox                          |"
        Write-Host "|  [7] Remove Mailbox                          |"
        Write-Host "|  [8] Convert Mailbox                         |"
        Write-Host "|  [9] Move Mailbox                            |"
        Write-Host "| [10] Mailbox Statistics                      |"
        Write-Host "| [11] Mailbox Permissions                     |"
        Write-Host "| [12] Email Addresses                         |"
        Write-Host "| [13] Mailbox Quotas                          |"
        Write-Host "| [14] Automatic Replies                       |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "2" {
                Search-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "3" {
                Show-PSFieldKitExchangeMailboxInformation -ExchangeContext $ExchangeContext
            }

            "4" {
                New-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "5" {
                Disable-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "6" {
                Enable-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "7" {
                Remove-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "8" {
                Convert-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "9" {
                Move-PSFieldKitExchangeMailbox -ExchangeContext $ExchangeContext
            }

            "10" {
                Get-PSFieldKitExchangeMailboxStatistics -ExchangeContext $ExchangeContext
            }

            "11" {
                Show-PSFieldKitExchangeMailboxPermissionsMenu -ExchangeContext $ExchangeContext
            }

            "12" {
                Show-PSFieldKitExchangeMailboxEmailAddressMenu -ExchangeContext $ExchangeContext
            }

            "13" {
                Set-PSFieldKitExchangeMailboxQuota -ExchangeContext $ExchangeContext
            }

            "14" {
                Set-PSFieldKitExchangeMailboxAutomaticReply -ExchangeContext $ExchangeContext
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