function Show-PSFieldKitExchangeSharedMailboxMenu {
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
        Write-Host "|                Shared Mailboxes              |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  SHARED MAILBOXES                            |" -ForegroundColor DarkCyan
        Write-Host "|  [1] List Shared Mailboxes                   |"
        Write-Host "|  [2] Search Shared Mailboxes                 |"
        Write-Host "|  [3] Shared Mailbox Information              |"
        Write-Host "|  [4] Create Shared Mailbox                   |"
        Write-Host "|  [5] Remove Shared Mailbox                   |"
        Write-Host "|  [6] Add Member                              |"
        Write-Host "|  [7] Remove Member                           |"
        Write-Host "|  [8] Manage Full Access                      |"
        Write-Host "|  [9] Manage Send As                          |"
        Write-Host "| [10] Manage Send on Behalf                   |"
        Write-Host "| [11] Email Addresses                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeSharedMailbox -ExchangeContext $ExchangeContext
            }

            "2" {
                Search-PSFieldKitExchangeSharedMailbox -ExchangeContext $ExchangeContext
            }

            "3" {
                Show-PSFieldKitExchangeSharedMailboxInformation -ExchangeContext $ExchangeContext
            }

            "4" {
                New-PSFieldKitExchangeSharedMailbox -ExchangeContext $ExchangeContext
            }

            "5" {
                Remove-PSFieldKitExchangeSharedMailbox -ExchangeContext $ExchangeContext
            }

            "6" {
                Add-PSFieldKitExchangeSharedMailboxMember -ExchangeContext $ExchangeContext
            }

            "7" {
                Remove-PSFieldKitExchangeSharedMailboxMember -ExchangeContext $ExchangeContext
            }

            "8" {
                Show-PSFieldKitExchangeSharedMailboxFullAccessMenu -ExchangeContext $ExchangeContext
            }

            "9" {
                Show-PSFieldKitExchangeSharedMailboxSendAsMenu -ExchangeContext $ExchangeContext
            }

            "10" {
                Show-PSFieldKitExchangeSharedMailboxSendOnBehalfMenu -ExchangeContext $ExchangeContext
            }

            "11" {
                Show-PSFieldKitExchangeSharedMailboxEmailAddressMenu -ExchangeContext $ExchangeContext
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