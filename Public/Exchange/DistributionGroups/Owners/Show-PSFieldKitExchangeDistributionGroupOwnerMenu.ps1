function Show-PSFieldKitExchangeDistributionGroupOwnerMenu {
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
        Write-Host "|          Distribution Group Owners           |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Show Owners                             |"
        Write-Host "|  [2] Add Owner                               |"
        Write-Host "|  [3] Remove Owner                            |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDistributionGroupOwner -ExchangeContext $ExchangeContext
            }

            '2' {
                Add-PSFieldKitExchangeDistributionGroupOwner -ExchangeContext $ExchangeContext
            }

            '3' {
                Remove-PSFieldKitExchangeDistributionGroupOwner -ExchangeContext $ExchangeContext
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