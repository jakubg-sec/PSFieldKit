function Show-ADDomainControllerMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|             Domain Controllers              |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Domain Controller Information           |"
        Write-Host "|  [2] List Domain Controllers                 |"
        Write-Host "|  [3] FSMO Roles                              |"
        Write-Host "|  [4] Services                                |"
        Write-Host "|  [5] SYSVOL / NETLOGON                       |"
        Write-Host "|  [6] Connectivity                            |"
        Write-Host "|  [7] Event Logs                              |"
        Write-Host "|  [8] DC Diagnostics                          |"
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
                Get-ADFSMORoles
                Pause
            }

            '4' {
                Get-ADDomainControllerServices
                Pause
            }

            '5' {
                Test-ADDomainControllerSYSVOL
                Pause
            }

            '6' {
                Test-ADDomainControllerConnectivity
                Pause
            }

            '7' {
                Get-ADDomainControllerEventLogs
                Pause
            }

            '8' {
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