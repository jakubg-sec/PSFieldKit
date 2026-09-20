function Show-PSFieldKitExchangeMailFlowMenu {
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
        Write-Host "|                  Mail Flow                   |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  MAIL FLOW                                   |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Send Connectors                         |"
        Write-Host "|  [2] Receive Connectors                      |"
        Write-Host "|  [3] Transport Rules                         |"
        Write-Host "|  [4] Message Tracking                        |"
        Write-Host "|  [5] Queue Management                        |"
        Write-Host "|  [6] Accepted Domains                        |"
        Write-Host "|  [7] Remote Domains                          |"
        Write-Host "|  [8] Email Address Policies                  |"
        Write-Host "|  [9] Test Mail Flow                          |"
        Write-Host "| [10] Mail Flow Configuration                 |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Show-PSFieldKitExchangeSendConnectorMenu -ExchangeContext $ExchangeContext
            }

            "2" {
                Show-PSFieldKitExchangeReceiveConnectorMenu -ExchangeContext $ExchangeContext
            }

            "3" {
                Show-PSFieldKitExchangeTransportRuleMenu -ExchangeContext $ExchangeContext
            }

            "4" {
                Show-PSFieldKitExchangeMessageTrackingMenu -ExchangeContext $ExchangeContext
            }

            "5" {
                Show-PSFieldKitExchangeQueueMenu -ExchangeContext $ExchangeContext
            }

            "6" {
                Show-PSFieldKitExchangeAcceptedDomainMenu -ExchangeContext $ExchangeContext
            }

            "7" {
                Show-PSFieldKitExchangeRemoteDomainMenu -ExchangeContext $ExchangeContext
            }

            "8" {
                Show-PSFieldKitExchangeEmailAddressPolicyMenu -ExchangeContext $ExchangeContext
            }

            "9" {
                Test-PSFieldKitExchangeMailFlow -ExchangeContext $ExchangeContext
            }

            "10" {
                Show-PSFieldKitExchangeMailFlowConfiguration -ExchangeContext $ExchangeContext
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