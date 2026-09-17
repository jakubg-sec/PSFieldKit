function Show-NetworkMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|           Network Diagnostics                |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Network Adapters                        |"
        Write-Host "|  [2] IP Configuration                        |"
        Write-Host "|  [3] Routing Table                           |"
        Write-Host "|  [4] ARP / Neighbor Table                    |"
        Write-Host "|  [5] DNS Diagnostics                         |"
        Write-Host "|  [6] Connectivity Tests                      |"
        Write-Host "|  [7] Ports & Connections                     |"
        Write-Host "|  [8] Network Statistics                      |"
        Write-Host "|  [9] Firewall Information                    |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-networkadapters -Context $Context
                Pause
            }

            '2' {
                Get-NetworkIPConfiguration -Context $Context
                Pause
            }

            '3' {
                Get-RoutingTable -Context $Context
                Pause
            }

            '4' {
                Get-NetworkNeighborTable -Context $Context
                Pause
            }

            '5' {
                Test-DNSDiagnostics -Context $Context
                Pause
            }

            '6' {
                Test-NetworkConnectivity -Context $Context
            }

            '7' {
                Get-PortsAndConnections -Context $Context
                Pause
            }

            '8' {
                Get-NetworkStatistics -Context $Context
                Pause
            }

            '9' {
                Get-FirewallInformation -Context $Context
                Pause
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