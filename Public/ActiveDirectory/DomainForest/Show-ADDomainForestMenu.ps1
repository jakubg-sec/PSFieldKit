function Show-ADDomainForestMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|         Domain & Forest Information          |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Domain Information                      |"
        Write-Host "|  [2] Forest Information                      |"
        Write-Host "|  [3] FSMO Roles                              |"
        Write-Host "|  [4] Domain Functional Level                 |"
        Write-Host "|  [5] Forest Functional Level                 |"
        Write-Host "|  [6] Sites & Subnets                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADDomainInformation
                Pause
            }

            '2' {
                Get-ADForestInformation
                Pause
            }

            '3' {
                Get-ADFSMORoles
                Pause
            }

            '4' {
                Get-ADDomainFunctionalLevel
                Pause
            }

            '5' {
                Get-ADForestFunctionalLevel
                Pause
            }

            '6' {
                Get-ADSiteInformation
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