function Show-ADMenu {

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "`nActive Directory PowerShell module is not installed." -ForegroundColor Red
        Write-Host "Install RSAT / Active Directory tools and try again." -ForegroundColor Yellow
        Pause
        return
    }

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Active Directory                |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Domain & Forest Information             |"
        Write-Host "|  [2] User Management                         |"
        Write-Host "|  [3] Computer Management                     |"
        Write-Host "|  [4] Group Management                        |"
        Write-Host "|  [5] Organizational Units                    |"
        Write-Host "|  [6] Domain Controllers                      |"
        Write-Host "|  [7] Group Policy                            |"
        Write-Host "|  [8] Replication                             |"
        Write-Host "|  [9] Trusts                                  |"
        Write-Host "| [10] AD Diagnostics                          |"
        Write-Host "| [11] Search Active Directory                 |"
        Write-Host "| [12] DNS                                     |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Show-ADDomainForestMenu
            }

            '2' {
                Show-ADUserMenu
            }

            '3' {
                Show-ADComputerMenu
            }

            '4' {
                Show-ADGroupMenu
            }

            '5' {
                Show-ADOrganizationalUnitMenu
            }

            '6' {
                Show-ADDomainControllerMenu
            }

            '7' {
                Show-ADGPOMenu
            }

            '8' {
                Show-ADReplicationMenu
            }

            '9' {
                Show-ADTrustMenu
            }

            '10' {
                Show-ADDiagnosticsMenu
            }

            '11' {
                Show-ADSearchMenu
            }

            '12' {
                Show-ADDnsMenu
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