function Show-PSFieldKitExchangeDatabaseQuotaMenu {
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
        Write-Host "|              Database Quotas                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  INFORMATION                                 |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Database Quotas                    |"
        Write-Host "|                                              |"
        Write-Host "|  MAILBOX QUOTAS                              |" -ForegroundColor DarkCyan
        Write-Host "|  [2] Set Issue Warning Quota                 |"
        Write-Host "|  [3] Set Prohibit Send Quota                 |"
        Write-Host "|  [4] Set Prohibit Send/Receive Quota         |"
        Write-Host "|                                              |"
        Write-Host "|  RECOVERABLE ITEMS                           |" -ForegroundColor DarkCyan
        Write-Host "|  [5] Set Recoverable Items Warning Quota     |"
        Write-Host "|  [6] Set Recoverable Items Quota             |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDatabaseQuota -ExchangeContext $ExchangeContext
            }
            '2' {
                Set-PSFieldKitExchangeDatabaseIssueWarningQuota -ExchangeContext $ExchangeContext
            }
            '3' {
                Set-PSFieldKitExchangeDatabaseProhibitSendQuota -ExchangeContext $ExchangeContext
            }
            '4' {
                Set-PSFieldKitExchangeDatabaseProhibitSendReceiveQuota -ExchangeContext $ExchangeContext
            }
            '5' {
                Set-PSFieldKitExchangeDatabaseRecoverableItemsWarningQuota -ExchangeContext $ExchangeContext
            }
            '6' {
                Set-PSFieldKitExchangeDatabaseRecoverableItemsQuota -ExchangeContext $ExchangeContext
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