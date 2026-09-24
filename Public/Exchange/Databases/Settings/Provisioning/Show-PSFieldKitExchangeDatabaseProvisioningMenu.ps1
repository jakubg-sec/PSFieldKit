function Show-PSFieldKitExchangeDatabaseProvisioningMenu {
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
        Write-Host "|            Database Provisioning             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  INFORMATION                                 |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Provisioning Settings              |"
        Write-Host "|                                              |"
        Write-Host "|  PROVISIONING                                |" -ForegroundColor DarkCyan
        Write-Host "|  [2] Configure Mailbox Provisioning          |"
        Write-Host "|  [3] Configure Initial Provisioning          |"
        Write-Host "|  [4] Configure Provisioning Suspension       |"
        Write-Host "|                                              |"
        Write-Host "|  MONITORING                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [5] Configure AutoDAG Monitoring            |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDatabaseProvisioning -ExchangeContext $ExchangeContext
            }
            '2' {
                Set-PSFieldKitExchangeDatabaseProvisioning -ExchangeContext $ExchangeContext
            }
            '3' {
                Set-PSFieldKitExchangeDatabaseInitialProvisioning -ExchangeContext $ExchangeContext
            }
            '4' {
                Set-PSFieldKitExchangeDatabaseProvisioningSuspension -ExchangeContext $ExchangeContext
            }
            '5' {
                Set-PSFieldKitExchangeDatabaseAutoDAGMonitoring -ExchangeContext $ExchangeContext
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