function Show-ADComputerMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|             Computer Management              |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Computer Information                    |"
        Write-Host "|  [2] Search Computers                        |"
        Write-Host "|  [3] Create Computer Account                 |"
        Write-Host "|  [4] Enable Computer                         |"
        Write-Host "|  [5] Disable Computer                        |"
        Write-Host "|  [6] Reset Computer Account                  |"
        Write-Host "|  [7] Move Computer                           |"
        Write-Host "|  [8] Remove Computer                         |"
        Write-Host "|  [9] Operating System Information            |"
        Write-Host "| [10] Last Logon Information                  |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADComputerInformation
                Pause
            }

            '2' {
                Search-ADComputers
                Pause
            }

            '3' {
                New-ADComputerAccount
                Pause
            }

            '4' {
                Enable-ADComputerAccount
                Pause
            }

            '5' {
                Disable-ADComputerAccount
                Pause
            }

            '6' {
                Reset-ADComputerAccount
                Pause
            }

            '7' {
                Move-ADComputerAccount
                Pause
            }

            '8' {
                Remove-ADComputerAccount
                Pause
            }

            '9' {
                Get-ADComputerOperatingSystem
                Pause
            }

            '10' {
                Get-ADComputerLastLogon
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