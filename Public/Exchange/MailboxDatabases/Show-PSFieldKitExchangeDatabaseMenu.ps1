function Show-PSFieldKitExchangeDatabaseMenu {
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
        Write-Host "|              Mailbox Databases               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  MAILBOX DATABASES                           |" -ForegroundColor DarkCyan
        Write-Host "|  [1] List Databases                          |"
        Write-Host "|  [2] Search Databases                        |"
        Write-Host "|  [3] Database Information                    |"
        Write-Host "|  [4] Database Statistics                     |"
        Write-Host "|  [5] Create Database                         |"
        Write-Host "|  [6] Remove Database                         |"
        Write-Host "|  [7] Mount Database                          |"
        Write-Host "|  [8] Dismount Database                       |"
        Write-Host "|  [9] Database Copy Status                    |"
        Write-Host "| [10] Move Active Database                    |"
        Write-Host "| [11] Database Paths                          |"
        Write-Host "| [12] Mailbox Database Configuration          |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "2" {
                Search-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "3" {
                Show-PSFieldKitExchangeDatabaseInformation -ExchangeContext $ExchangeContext
            }

            "4" {
                Get-PSFieldKitExchangeDatabaseStatistics -ExchangeContext $ExchangeContext
            }

            "5" {
                New-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "6" {
                Remove-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "7" {
                Mount-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "8" {
                Dismount-PSFieldKitExchangeDatabase -ExchangeContext $ExchangeContext
            }

            "9" {
                Get-PSFieldKitExchangeDatabaseCopyStatus -ExchangeContext $ExchangeContext
            }

            "10" {
                Move-PSFieldKitExchangeActiveDatabase -ExchangeContext $ExchangeContext
            }

            "11" {
                Show-PSFieldKitExchangeDatabasePath -ExchangeContext $ExchangeContext
            }

            "12" {
                Show-PSFieldKitExchangeDatabaseConfiguration -ExchangeContext $ExchangeContext
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