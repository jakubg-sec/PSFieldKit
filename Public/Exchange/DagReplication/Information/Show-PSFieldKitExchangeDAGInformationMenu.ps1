function Show-PSFieldKitExchangeDAGInformationMenu {
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

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              DAG INFORMATION                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] DAG List                                |"
        Write-Host "|  [2] DAG Details                             |"
        Write-Host "|  [3] DAG Members                             |"
        Write-Host "|  [4] DAG Networks                            |"
        Write-Host "|  [5] DAG Databases                           |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeDAGList -ExchangeContext $ExchangeContext
            }

            "2" {
                Get-PSFieldKitExchangeDAGDetails -ExchangeContext $ExchangeContext
            }

            "3" {
                Get-PSFieldKitExchangeDAGMembers -ExchangeContext $ExchangeContext
            }

            "4" {
                Get-PSFieldKitExchangeDAGNetworks -ExchangeContext $ExchangeContext
            }

            "5" {
                Get-PSFieldKitExchangeDAGDatabases -ExchangeContext $ExchangeContext
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