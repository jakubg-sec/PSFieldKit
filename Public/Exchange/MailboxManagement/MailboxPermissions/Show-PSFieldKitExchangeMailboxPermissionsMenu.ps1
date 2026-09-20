function Show-PSFieldKitExchangeMailboxPermissionsMenu {
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
        Write-Host "|              Mailbox Permissions             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        Write-Host "|  MAILBOX PERMISSIONS                         |" -ForegroundColor DarkCyan
        Write-Host "|  [1] View Mailbox Permissions                |"
        Write-Host "|  [2] Add Full Access                         |"
        Write-Host "|  [3] Remove Full Access                      |"
        Write-Host "|  [4] Add Send As                             |"
        Write-Host "|  [5] Remove Send As                          |"
        Write-Host "|  [6] Add Send on Behalf                     |"
        Write-Host "|  [7] Remove Send on Behalf                  |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeMailboxPermissions -ExchangeContext $ExchangeContext
            }

            "2" {
                Add-PSFieldKitExchangeMailboxFullAccess -ExchangeContext $ExchangeContext
            }

            "3" {
                Remove-PSFieldKitExchangeMailboxFullAccess -ExchangeContext $ExchangeContext
            }

            "4" {
                Add-PSFieldKitExchangeMailboxSendAs -ExchangeContext $ExchangeContext
            }

            "5" {
                Remove-PSFieldKitExchangeMailboxSendAs -ExchangeContext $ExchangeContext
            }

            "6" {
                Add-PSFieldKitExchangeMailboxSendOnBehalf -ExchangeContext $ExchangeContext
            }

            "7" {
                Remove-PSFieldKitExchangeMailboxSendOnBehalf -ExchangeContext $ExchangeContext
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