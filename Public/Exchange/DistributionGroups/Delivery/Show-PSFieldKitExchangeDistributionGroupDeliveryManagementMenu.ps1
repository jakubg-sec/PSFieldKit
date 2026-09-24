function Show-PSFieldKitExchangeDistributionGroupDeliveryManagementMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        return
    }

    while ($true) {
        Clear-Host

        $ServerName = "Unknown"

        if (
            $ExchangeContext.PSObject.Properties.Name -contains 'ServerName' -and
            -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
        ) {
            $ServerName = [string]$ExchangeContext.ServerName
        }

        if ($ServerName.Length -gt 35) {
            $ServerName = $ServerName.Substring(0, 32) + "..."
        }

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|            Delivery Management               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  DELIVERY SETTINGS                           |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Delivery Settings                  |"
        Write-Host "|  [2] Configure Sender Authentication         |"
        Write-Host "|                                              |"
        Write-Host "|  ALLOWED SENDERS                             |" -ForegroundColor DarkCyan
        Write-Host "|  [3] Manage Allowed Senders                  |"
        Write-Host "|                                              |"
        Write-Host "|  BLOCKED SENDERS                             |" -ForegroundColor DarkCyan
        Write-Host "|  [4] Manage Blocked Senders                  |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDistributionGroupDeliverySettings -ExchangeContext $ExchangeContext
            }

            '2' {
                Set-PSFieldKitExchangeDistributionGroupSenderAuthentication -ExchangeContext $ExchangeContext
            }

            '3' {
                Show-PSFieldKitExchangeDistributionGroupAllowedSenderMenu -ExchangeContext $ExchangeContext
            }

            '4' {
                Show-PSFieldKitExchangeDistributionGroupBlockedSenderMenu -ExchangeContext $ExchangeContext
            }

            '0' {
                return
            }

            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}