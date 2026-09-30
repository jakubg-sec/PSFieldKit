function Show-PSFieldKitExchangeDAGMemberStatusMenu {
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
        Write-Host "|             DAG MEMBER STATUS               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                  |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] All DAG Members                         |"
        Write-Host "|  [2] Healthy Members                         |"
        Write-Host "|  [3] Unhealthy Members                       |"
        Write-Host "|  [4] Member Details                           |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeDAGMembers `
                    -ExchangeContext $ExchangeContext
            }

            "2" {
                Get-PSFieldKitExchangeDAGMembers `
                    -ExchangeContext $ExchangeContext |
                    Where-Object {
                        $_.OperationalServer -eq $true
                    }
            }

            "3" {
                Get-PSFieldKitExchangeDAGMembers `
                    -ExchangeContext $ExchangeContext |
                    Where-Object {
                        $_.OperationalServer -ne $true
                    }
            }

            "4" {
                Show-PSFieldKitExchangeDAGMemberDetails `
                    -ExchangeContext $ExchangeContext
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