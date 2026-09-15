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
        Write-Host "|  [4] Windows Services                        |"
        Write-Host "|  [5] Windows Update Status                   |"
        Write-Host "|  [6] Available Updates                       |"
        Write-Host "|  [7] Installed Updates                       |"
        Write-Host "|  [8] Update History                          |"
        Write-Host "|  [9] Check for Updates                       |"
        Write-Host "| [10] Pending Reboot Status                   |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Get-InstalledSoftware
            }

            '2' {
                # Get-SoftwareDetails
            }

            '3' {
                # Get-WindowsFeatureInformation
            }

            '4' {
                # Get-WindowsServiceInformation
            }

            '5' {
                # Get-WindowsUpdateStatus
            }

            '6' {
                # Get-AvailableUpdates
            }

            '7' {
                # Get-InstalledUpdates
            }

            '8' {
                # Get-UpdateHistory
            }

            '9' {
                # Find-WindowsUpdates
            }

            '10' {
                # Get-PendingRebootStatus
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