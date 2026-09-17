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
                Get-SystemInformation -Context $Context | Format-List
                Pause
            }

            '2' {
                Get-OperatingSystemInformation -Context $Context | Format-List
                Pause
            }

            '3' {
                Get-HardwareInformation -Context $Context | Format-List
                Pause
            }

            '4' {
                Get-CPUInformation -Context $Context | Format-List
                Pause
            }

            '5' {
                Get-MemoryInformation -Context $Context | Format-List
                Pause
            }

            '6' {
                Get-DiskInformation -Context $Context
                Pause
            }

            '7' {
                Get-NetworkAdapterInformation -Context $Context | Format-Table -AutoSize
                Pause
            }

            '8' {
                Get-Uptime -Context $Context | Format-List
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