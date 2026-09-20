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
        Write-Host "|  DAG MANAGEMENT                              |" -ForegroundColor DarkCyan
        Write-Host "|  [1] DAG Information                         |"
        Write-Host "|  [2] DAG Member Status                       |"
        Write-Host "|  [3] Database Replication Health             |"
        Write-Host "|  [4] Activate Database Copy                  |"
        Write-Host "|  [5] Suspend Database Copy                   |"
        Write-Host "|  [6] Resume Database Copy                    |"
        Write-Host "|  [7] Update Database Copy                    |"
        Write-Host "|  [8] ReSeed Database Copy                    |"
        Write-Host "|  [9] Add DAG Member                          |"
        Write-Host "| [10] Remove DAG Member                       |"
        Write-Host "| [11] DAG Network Information                 |"
        Write-Host "| [12] Database Availability                   |"
        Write-Host "| [13] DAG Health Check                        |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Show-PSFieldKitExchangeDAGInformation -ExchangeContext $ExchangeContext
            }

            "2" {
                Show-PSFieldKitExchangeDAGMemberStatus -ExchangeContext $ExchangeContext
            }

            "3" {
                Test-PSFieldKitExchangeDatabaseReplication -ExchangeContext $ExchangeContext
            }

            "4" {
                Move-PSFieldKitExchangeActiveDatabase -ExchangeContext $ExchangeContext
            }

            "5" {
                Suspend-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "6" {
                Resume-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "7" {
                Update-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            "8" {
                Invoke-PSFieldKitExchangeDatabaseReseed -ExchangeContext $ExchangeContext
            }

            "9" {
                Add-PSFieldKitExchangeDAGMember -ExchangeContext $ExchangeContext
            }

            "10" {
                Remove-PSFieldKitExchangeDAGMember -ExchangeContext $ExchangeContext
            }

            "11" {
                Show-PSFieldKitExchangeDAGNetwork -ExchangeContext $ExchangeContext
            }

            "12" {
                Show-PSFieldKitExchangeDatabaseAvailability -ExchangeContext $ExchangeContext
            }

            "13" {
                Test-PSFieldKitExchangeDAGHealth -ExchangeContext $ExchangeContext
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