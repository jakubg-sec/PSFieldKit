function Show-ADDiagnosticsMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|               AD Diagnostics                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] AD Health Summary                       |"
        Write-Host "|  [2] DCDIAG                                  |"
        Write-Host "|  [3] DNS Diagnostics                         |"
        Write-Host "|  [4] SYSVOL Test                             |"
        Write-Host "|  [5] Netlogon Test                           |"
        Write-Host "|  [6] LDAP Connectivity                       |"
        Write-Host "|  [7] Kerberos Test                           |"
        Write-Host "|  [8] Time Synchronization                    |"
        Write-Host "|  [9] Domain Controller Diagnostics           |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADHealthSummary
                Pause
            }

            '2' {
                Test-ADDCDIAG
                Pause
            }

            '3' {
                Test-ADDNSDiagnostics
                Pause
            }

            '4' {
                Test-ADSYSVOL
                Pause
            }

            '5' {
                Test-ADNetlogon
                Pause
            }

            '6' {
                Test-ADLDAPConnectivity
                Pause
            }

            '7' {
                Test-ADKerberos
                Pause
            }

            '8' {
                Test-ADTimeSynchronization
                Pause
            }

            '9' {
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