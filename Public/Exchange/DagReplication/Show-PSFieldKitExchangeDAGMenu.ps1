function Show-PSFieldKitExchangeDAGMenu {
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
        Write-Host "|              DAG & Replication               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  DAG INFORMATION                             |" -ForegroundColor DarkCyan
        Write-Host "|  [1] DAG Information                         |"
        Write-Host "|  [2] DAG Health Check                        |"
        Write-Host "|                                              |"
        Write-Host "|  DATABASE OPERATIONS                         |" -ForegroundColor DarkCyan
        Write-Host "|  [3] Add Database Copy                       |"
        Write-Host "|  [4] Remove Database Copy                    |"
        Write-Host "|  [5] Activate Database Copy                  |"
        Write-Host "|  [6] Suspend Database Copy                   |"
        Write-Host "|  [7] Resume Database Copy                    |"
        Write-Host "|  [8] Update Database Copy                    |"
        Write-Host "|  [9] ReSeed Database Copy                    |"
        Write-Host "|                                              |"
        Write-Host "|  DAG MEMBERS                                 |" -ForegroundColor DarkCyan
        Write-Host "| [10] Add DAG Member                          |"
        Write-Host "| [11] Remove DAG Member                       |"
        Write-Host "|                                              |"
        Write-Host "|  DAG MANAGEMENT                              |" -ForegroundColor DarkCyan
        Write-Host "| [12] Create DAG                              |"
        Write-Host "| [13] Remove DAG                              |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Show-PSFieldKitExchangeDAGInformationMenu -ExchangeContext $ExchangeContext
            }

            "2" {
                Test-PSFieldKitExchangeDAGHealth -ExchangeContext $ExchangeContext
            }

            "3" {
                Add-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "4" {
                Remove-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "5" {
                Move-PSFieldKitExchangeActiveDatabase -ExchangeContext $ExchangeContext
            }

            "6" {
                Suspend-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "7" {
                Resume-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "8" {
                Update-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "9" {
                Invoke-PSFieldKitExchangeDatabaseReseed -ExchangeContext $ExchangeContext
            }

            "10" {
                Add-PSFieldKitExchangeDAGMember -ExchangeContext $ExchangeContext
            }

            "11" {
                Remove-PSFieldKitExchangeDAGMember -ExchangeContext $ExchangeContext
            }

            "12" {
                New-PSFieldKitExchangeDAG -ExchangeContext $ExchangeContext
            }

            "13" {
                Remove-PSFieldKitExchangeDAG -ExchangeContext $ExchangeContext
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