function Show-PSFieldKitExchangeDistributionGroupAllowedSenderMenu {
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

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Allowed Senders                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Show Allowed Senders                    |"
        Write-Host "|  [2] Add Allowed Sender                      |"
        Write-Host "|  [3] Remove Allowed Sender                   |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDistributionGroupAllowedSender -ExchangeContext $ExchangeContext
            }

            '2' {
                Add-PSFieldKitExchangeDistributionGroupAllowedSender -ExchangeContext $ExchangeContext
            }

            '3' {
                Remove-PSFieldKitExchangeDistributionGroupAllowedSender -ExchangeContext $ExchangeContext
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