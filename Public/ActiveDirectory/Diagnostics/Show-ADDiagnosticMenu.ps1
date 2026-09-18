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
        Write-Host "|  [4] LDAP Connectivity                       |"
        Write-Host "|  [5] Kerberos Test                           |"
        Write-Host "|  [6] Time Synchronization                    |"
        Write-Host "|  [7] SYSVOL / NETLOGON                       |"
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
                Test-ADLDAPConnectivity
                Pause
            }
            '5' {
                Test-ADKerberos
                Pause
            }
            '6' {
                Test-ADTimeSynchronization
                Pause
            }
            '7' {
                Test-ADSYSVOLNetlogon
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