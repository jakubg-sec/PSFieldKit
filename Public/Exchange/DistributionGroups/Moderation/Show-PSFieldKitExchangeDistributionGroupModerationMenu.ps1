function Show-PSFieldKitExchangeDistributionGroupModerationMenu {
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
        Write-Host "|          Distribution Group Moderation       |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  MODERATION                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Moderation Settings                |"
        Write-Host "|  [2] Enable Moderation                       |"
        Write-Host "|  [3] Disable Moderation                      |"
        Write-Host "|                                              |"
        Write-Host "|  MODERATORS                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [4] Show Moderators                         |"
        Write-Host "|  [5] Add Moderator                           |"
        Write-Host "|  [6] Remove Moderator                        |"
        Write-Host "|                                              |"
        Write-Host "|  NOTIFICATIONS                               |" -ForegroundColor DarkCyan
        Write-Host "|  [7] Moderation Notifications                |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Show-PSFieldKitExchangeDistributionGroupModerationSettings -ExchangeContext $ExchangeContext
            }

            '2' {
                Enable-PSFieldKitExchangeDistributionGroupModeration -ExchangeContext $ExchangeContext
            }

            '3' {
                Disable-PSFieldKitExchangeDistributionGroupModeration -ExchangeContext $ExchangeContext
            }

            '4' {
                Show-PSFieldKitExchangeDistributionGroupModerator -ExchangeContext $ExchangeContext
            }

            '5' {
                Add-PSFieldKitExchangeDistributionGroupModerator -ExchangeContext $ExchangeContext
            }

            '6' {
                Remove-PSFieldKitExchangeDistributionGroupModerator -ExchangeContext $ExchangeContext
            }

            '7' {
                Set-PSFieldKitExchangeDistributionGroupModerationNotification -ExchangeContext $ExchangeContext
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