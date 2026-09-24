function Show-PSFieldKitExchangeDistributionGroupMenu {
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
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
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
        Write-Host "|              Distribution Groups             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  DISTRIBUTION GROUPS                         |" -ForegroundColor DarkCyan
        Write-Host "|  [1] List Distribution Groups                |"
        Write-Host "|  [2] Search Distribution Groups              |"
        Write-Host "|  [3] Distribution Group Information          |"
        Write-Host "|  [4] Create Distribution Group               |"
        Write-Host "|  [5] Remove Distribution Group               |"
        Write-Host "|  [6] Add Member                              |"
        Write-Host "|  [7] Remove Member                           |"
        Write-Host "|  [8] Manage Owners                           |"
        Write-Host "|  [9] Delivery Management                     |"
        Write-Host "| [10] Message Moderation                      |"
        Write-Host "| [11] Email Addresses                         |"
        Write-Host "| [12] Show Members                            |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeDistributionGroup -ExchangeContext $ExchangeContext
            }
            "2" {
                Search-PSFieldKitExchangeDistributionGroup -ExchangeContext $ExchangeContext
            }
            "3" {
                Show-PSFieldKitExchangeDistributionGroupInformation -ExchangeContext $ExchangeContext
            }
            "4" {
                New-PSFieldKitExchangeDistributionGroup -ExchangeContext $ExchangeContext
            }
            "5" {
                Remove-PSFieldKitExchangeDistributionGroup -ExchangeContext $ExchangeContext
            }
            "6" {
                Add-PSFieldKitExchangeDistributionGroupMember -ExchangeContext $ExchangeContext
            }
            "7" {
                Remove-PSFieldKitExchangeDistributionGroupMember -ExchangeContext $ExchangeContext
            }
            "8" {
                Show-PSFieldKitExchangeDistributionGroupOwnerMenu -ExchangeContext $ExchangeContext
            }
            "9" {
                Show-PSFieldKitExchangeDistributionGroupDeliveryManagementMenu -ExchangeContext $ExchangeContext
            }
            "10" {
                Show-PSFieldKitExchangeDistributionGroupModerationMenu -ExchangeContext $ExchangeContext
            }
            "11" {
                Show-PSFieldKitExchangeDistributionGroupEmailAddressMenu -ExchangeContext $ExchangeContext
            }
            "12" {
                Get-PSFieldKitExchangeDistributionGroupMember -ExchangeContext $ExchangeContext
            }
            "0" {
                return
            }
            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}