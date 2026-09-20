function Show-PSFieldKitExchangeMailboxEmailAddressMenu {
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
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
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
        Write-Host "|             Mailbox Email Addresses          |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        Write-Host "|  EMAIL ADDRESSES                             |" -ForegroundColor DarkCyan
        Write-Host "|  [1] View Email Addresses                    |"
        Write-Host "|  [2] Add Email Address                       |"
        Write-Host "|  [3] Remove Email Address                    |"
        Write-Host "|  [4] Set Primary Email Address               |"
        Write-Host "|  [5] Enable Email Address Policy             |"
        Write-Host "|  [6] Disable Email Address Policy            |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeMailboxEmailAddresses -ExchangeContext $ExchangeContext
            }

            "2" {
                Add-PSFieldKitExchangeMailboxEmailAddress -ExchangeContext $ExchangeContext
            }

            "3" {
                Remove-PSFieldKitExchangeMailboxEmailAddress -ExchangeContext $ExchangeContext
            }

            "4" {
                Set-PSFieldKitExchangeMailboxPrimaryEmailAddress -ExchangeContext $ExchangeContext
            }

            "5" {
                Enable-PSFieldKitExchangeMailboxEmailAddressPolicy -ExchangeContext $ExchangeContext
            }

            "6" {
                Disable-PSFieldKitExchangeMailboxEmailAddressPolicy -ExchangeContext $ExchangeContext
            }

            "0" {
                return
            }

            default {
                Write-Host ""
                Write-Host "Invalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}