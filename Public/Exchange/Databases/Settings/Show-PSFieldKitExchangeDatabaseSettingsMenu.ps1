function Show-PSFieldKitExchangeDatabaseSettingsMenu {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|            Database Settings                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  GENERAL                                     |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Database Settings                  |"
        Write-Host "|  [2] Set Database Settings                   |"
        Write-Host "|                                              |"
        Write-Host "|  QUOTAS & RETENTION                          |" -ForegroundColor DarkCyan
        Write-Host "|  [3] Configure Mailbox Quotas                |"
        Write-Host "|  [4] Configure Deleted Item Retention        |"
        Write-Host "|  [5] Configure Mailbox Retention             |"
        Write-Host "|                                              |"
        Write-Host "|  LOGGING & MAINTENANCE                       |" -ForegroundColor DarkCyan
        Write-Host "|  [6] Configure Circular Logging              |"
        Write-Host "|  [7] Configure Database Maintenance          |"
        Write-Host "|                                              |"
        Write-Host "|  PROVISIONING                                |" -ForegroundColor DarkCyan
        Write-Host "|  [8] Configure Provisioning                  |"
        Write-Host "|                                              |"
        Write-Host "|  OTHER                                       |" -ForegroundColor DarkCyan
        Write-Host "|  [9] Configure Mount at Startup              |"
        Write-Host "| [10] Configure Offline Address Book          |"
        Write-Host "| [11] Configure Journaling                    |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Show-PSFieldKitExchangeDatabaseSettings -ExchangeContext $ExchangeContext
            }

            '2' {
                Set-PSFieldKitExchangeDatabaseSettings -ExchangeContext $ExchangeContext
            }

            '3' {
                Show-PSFieldKitExchangeDatabaseQuotaMenu -ExchangeContext $ExchangeContext
            }

            '4' {
                Set-PSFieldKitExchangeDatabaseDeletedItemRetention -ExchangeContext $ExchangeContext
            }

            '5' {
                Set-PSFieldKitExchangeDatabaseMailboxRetention -ExchangeContext $ExchangeContext
            }

            '6' {
                Set-PSFieldKitExchangeDatabaseCircularLogging -ExchangeContext $ExchangeContext
            }

            '7' {
                Set-PSFieldKitExchangeDatabaseMaintenance -ExchangeContext $ExchangeContext
            }

            '8' {
                Show-PSFieldKitExchangeDatabaseProvisioningMenu -ExchangeContext $ExchangeContext
            }

            '9' {
                Set-PSFieldKitExchangeDatabaseMountAtStartup -ExchangeContext $ExchangeContext
            }

            '10' {
                Set-PSFieldKitExchangeDatabaseOfflineAddressBook -ExchangeContext $ExchangeContext
            }

            '11' {
                Set-PSFieldKitExchangeDatabaseJournaling -ExchangeContext $ExchangeContext
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