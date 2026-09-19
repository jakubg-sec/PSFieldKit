function Show-ProcessServiceMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Processes & Services                |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Process Information                     |"
        Write-Host "|  [2] Running Processes                       |"
        Write-Host "|  [3] Process Details                         |"
        Write-Host "|  [4] Service Information                     |"
        Write-Host "|  [5] Running Services                        |"
        Write-Host "|  [6] Start Service                           |"
        Write-Host "|  [7] Stop Service                            |"
        Write-Host "|  [8] Restart Service                         |"
        Write-Host "|  [9] Service Dependencies                    |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ProcessInformation -Context $Context
                Pause
            }

            '2' {
                Get-RunningProcesses -Context $Context
                Pause
            }

            '3' {
                Get-ProcessDetails -Context $Context
                Pause
            }

            '4' {
                Get-ServiceInformation -Context $Context
                Pause
            }

            '5' {
                Get-RunningServices -Context $Context
                Pause
            }

            '6' {
                Start-PSFieldKitService -Context $Context
                Pause
            }

            '7' {
                Stop-PSFieldKitService -Context $Context
                Pause
            }

            '8' {
                Restart-PSFieldKitService -Context $Context
                Pause
            }

            '9' {
                Get-ServiceDependencies -Context $Context
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