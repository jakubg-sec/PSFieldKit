function Show-PSFieldKitExchangeDistributionGroupEmailAddressMenu {
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
        Write-Host "|       Distribution Group Email Addresses     |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  EMAIL ADDRESSES                             |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Email Addresses                    |"
        Write-Host "|  [2] Add Email Address                       |"
        Write-Host "|  [3] Remove Email Address                    |"
        Write-Host "|  [4] Set Primary SMTP Address                |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDistributionGroupEmailAddress -ExchangeContext $ExchangeContext
            }

            '2' {
                Add-PSFieldKitExchangeDistributionGroupEmailAddress -ExchangeContext $ExchangeContext
            }

            '3' {
                Remove-PSFieldKitExchangeDistributionGroupEmailAddress -ExchangeContext $ExchangeContext
            }

            '4' {
                Set-PSFieldKitExchangeDistributionGroupPrimaryEmailAddress -ExchangeContext $ExchangeContext
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