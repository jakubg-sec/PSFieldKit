function Show-PSFieldKitExchangeDatabaseMenu {
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
        Write-Host "|            Mailbox Databases                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  DATABASE INFORMATION                        |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Mailbox Databases                  |"
        Write-Host "|  [2] Search Mailbox Databases                |"
        Write-Host "|  [3] Database Information                    |"
        Write-Host "|                                              |"
        Write-Host "|  DATABASE OPERATIONS                         |" -ForegroundColor DarkCyan
        Write-Host "|  [4] Mount Database                          |"
        Write-Host "|  [5] Dismount Database                       |"
        Write-Host "|  [6] Create Mailbox Database                 |"
        Write-Host "|  [7] Remove Mailbox Database                 |"
        Write-Host "|                                              |"
        Write-Host "|  CONFIGURATION & COPIES                      |" -ForegroundColor DarkCyan
        Write-Host "|  [8] Database Settings                       |"
        Write-Host "|  [9] Database Copies                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Get-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '2' {
                Search-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '3' {
                Show-PSFieldKitExchangeDatabaseInformation -ExchangeContext $ExchangeContext
            }

            '4' {
                Mount-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '5' {
                Dismount-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '6' {
                New-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '7' {
                Remove-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            '8' {
                Show-PSFieldKitExchangeDatabaseSettingsMenu -ExchangeContext $ExchangeContext
            }

            '9' {
                Show-PSFieldKitExchangeDatabaseCopyMenu -ExchangeContext $ExchangeContext
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