function Show-PSFieldKitExchangeHealthMenu {
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
        Write-Host "|                Exchange Health               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  HEALTH CHECKS                               |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Server Health                           |"
        Write-Host "|  [2] Component State                         |"
        Write-Host "|  [3] Exchange Service Health                 |"
        Write-Host "|  [4] Mailbox Database Health                 |"
        Write-Host "|  [5] Exchange Health Report                  |"
        Write-Host "|  [6] Run Full Health Check                   |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeServerHealth -ExchangeContext $ExchangeContext
            }

            "2" {
                Get-PSFieldKitExchangeComponentState -ExchangeContext $ExchangeContext
            }

            "3" {
                Get-PSFieldKitExchangeServiceHealth -ExchangeContext $ExchangeContext
            }

            "4" {
                Get-PSFieldKitExchangeMailboxDatabaseHealth -ExchangeContext $ExchangeContext
            }

            "5" {
                Show-PSFieldKitExchangeHealthReport -ExchangeContext $ExchangeContext
            }

            "6" {
                Start-PSFieldKitExchangeFullHealthCheck -ExchangeContext $ExchangeContext
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