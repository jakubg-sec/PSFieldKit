function Show-ADOrganizationalUnitMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|           Organizational Units               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] OU Tree                                 |"
        Write-Host "|  [2] OU Information                          |"
        Write-Host "|  [3] Search OUs                              |"
        Write-Host "|  [4] Create OU                               |"
        Write-Host "|  [5] Rename OU                               |"
        Write-Host "|  [6] Move Object                             |"
        Write-Host "|  [7] Remove OU                               |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADOUTree
                Pause
            }

            '2' {
                Get-ADOUInformation
                Pause
            }

            '3' {
                Search-ADOUs
                Pause
            }

            '4' {
                New-ADOrganizationalUnit
                Pause
            }

            '5' {
                Rename-ADOrganizationalUnit
                Pause
            }

            '6' {
                Move-ADObject
                Pause
            }

            '7' {
                Remove-ADOrganizationalUnit
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