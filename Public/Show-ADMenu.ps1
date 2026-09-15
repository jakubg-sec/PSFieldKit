function Show-ADMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Active Directory                |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] User Management                         |"
        Write-Host "|  [2] Computer Management                     |"
        Write-Host "|  [3] Group Management                        |"
        Write-Host "|  [4] Organizational Units                    |"
        Write-Host "|  [5] Domain Controllers                      |"
        Write-Host "|  [6] Group Policy                            |"
        Write-Host "|  [7] Replication                             |"
        Write-Host "|  [8] DNS                                     |"
        Write-Host "|  [9] AD Diagnostics                          |"
        Write-Host "| [10] Search Active Directory                 |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Show-ADUserMenu
            }

            '2' {
                # Show-ADComputerMenu
            }

            '3' {
                # Show-ADGroupMenu
            }

            '4' {
                # Show-ADOrganizationalUnitMenu
            }

            '5' {
                # Show-ADDomainControllerMenu
            }

            '6' {
                # Show-ADGPOMenu
            }

            '7' {
                # Show-ADReplicationMenu
            }

            '8' {
                # Show-ADDnsMenu
            }

            '9' {
                # Show-ADDiagnosticsMenu
            }

            '10' {
                # Search-ActiveDirectory
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