function Show-ComputerMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Computer Information                |" -ForegroundColor Cyan
        Write-Host "|              PSFieldKit                      |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] System Information                      |"
        Write-Host "|  [2] Operating System Information            |"
        Write-Host "|  [3] Hardware Information                    |"
        Write-Host "|  [4] CPU Information                         |"
        Write-Host "|  [5] Memory Information                      |"
        Write-Host "|  [6] Disk Information                        |"
        Write-Host "|  [7] Network Adapter Information             |"
        Write-Host "|  [8] Uptime                                  |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Write-Host "Target: $($Context.ComputerName)"
                Pause
            }

            '2' {
                Write-Host "Target: $($Context.ComputerName)"
                Pause
            }

            '3' {
                Write-Host "Target: $($Context.ComputerName)"
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