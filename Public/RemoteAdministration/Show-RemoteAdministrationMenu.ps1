function Show-RemoteAdministrationMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Remote Administration               |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Test Remote Connectivity                |"
        Write-Host "|  [2] Test WinRM                              |"
        Write-Host "|  [3] Create PSSession                        |"
        Write-Host "|  [4] Remove PSSession                        |"
        Write-Host "|  [5] Session Information                     |"
        Write-Host "|  [6] Invoke Remote Command                   |"
        Write-Host "|  [7] Invoke Remote Script                    |"
        Write-Host "|  [8] CIM / WMI Remote Query                  |"
        Write-Host "|  [9] Remote Computer Management              |"
        Write-Host "| [10] Remote Reboot / Shutdown                |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Test-PSFieldKitConnection
            }

            '2' {
                # Test-PSFieldKitWinRM
            }

            '3' {
                # New-PSFieldKitSession
            }

            '4' {
                # Remove-PSFieldKitSession
            }

            '5' {
                # Get-PSFieldKitSession
            }

            '6' {
                # Invoke-PSFieldKitCommand
            }

            '7' {
                # Invoke-PSFieldKitScript
            }

            '8' {
                # Invoke-PSFieldKitCimQuery
            }

            '9' {
                # Show-RemoteComputerManagement
            }

            '10' {
                # Restart-PSFieldKitComputer
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