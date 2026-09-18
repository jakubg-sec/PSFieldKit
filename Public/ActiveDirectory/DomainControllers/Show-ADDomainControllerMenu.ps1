function Show-ADDomainControllerMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Domain Controllers              |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Domain Controller Information           |"
        Write-Host "|  [2] List Domain Controllers                 |"
        Write-Host "|  [3] Services                                |"
        Write-Host "|  [4] SYSVOL / NETLOGON                       |"
        Write-Host "|  [5] Connectivity                            |"
        Write-Host "|  [6] Event Logs                              |"
        Write-Host "|  [7] DC Diagnostics                          |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADDomainControllerInformation
                Pause
            }

            '2' {
                Get-ADDomainControllers
                Pause
            }

            '3' {
                Get-ADDomainControllerServices
                Pause
            }

            '4' {
                Test-ADDomainControllerSYSVOL
                Pause
            }

            '5' {
                Test-ADDomainControllerConnectivity
                Pause
            }

            '6' {
                Get-ADDomainControllerEventLogs
                Pause
            }

            '7' {
                Test-ADDomainControllerDiagnostics
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