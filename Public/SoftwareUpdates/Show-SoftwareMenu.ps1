function Show-SoftwareMenu {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|           Software & Updates                 |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Installed Software                      |"
        Write-Host "|  [2] Software Details                        |"
        Write-Host "|  [3] Windows Features                        |"
        Write-Host "|  [4] Windows Update Status                   |"
        Write-Host "|  [5] Available Updates                       |"
        Write-Host "|  [6] Installed Updates                       |"
        Write-Host "|  [7] Update History                          |"
        Write-Host "|  [8] Check for Updates                       |"
        Write-Host "|  [9] Pending Reboot Status                   |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        if ($Context.IsMultiTarget) {
            Write-Host "`nTarget: Multiple Computers ($($Context.Targets.Count) hosts)" `
                -ForegroundColor Yellow
        }
        else {
            Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow
        }

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Get-InstalledSoftware -Context $Context
                Pause
            }

            '2' {
                Get-SoftwareDetails -Context $Context
                Pause
            }

            '3' {
                Get-WindowsFeatureInformation -Context $Context
                Pause
            }

            '4' {
                Get-WindowsUpdateStatus -Context $Context
                Pause
            }

            '5' {
                Get-AvailableUpdates -Context $Context
                Pause
            }

            '6' {
                Get-InstalledUpdates -Context $Context
                Pause
            }

            '7' {
                Get-UpdateHistory -Context $Context
                Pause
            }

            '8' {
                Find-WindowsUpdates -Context $Context
                Pause
            }

            '9' {
                Get-PendingRebootStatus -Context $Context
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