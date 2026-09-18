function Show-ADDnsMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                  AD DNS                      |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] DNS Server Information                  |"
        Write-Host "|  [2] DNS Zones                               |"
        Write-Host "|  [3] Zone Information                        |"
        Write-Host "|  [4] DNS Records                             |"
        Write-Host "|  [5] DNS Forwarders                          |"
        Write-Host "|  [6] DNS Scavenging                          |"
        Write-Host "|  [7] DNS Server Statistics                   |"
        Write-Host "|  [8] DNS Diagnostics                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADDnsServerInformation
                Pause
            }

            '2' {
                Get-ADDnsZones
                Pause
            }

            '3' {
                Get-ADDnsZoneInformation
                Pause
            }

            '4' {
                Get-ADDnsRecords
                Pause
            }

            '5' {
                Get-ADDnsForwarders
                Pause
            }

            '6' {
                Get-ADDnsScavenging
                Pause
            }

            '7' {
                Get-ADDnsServerStatistics
                Pause
            }

            '8' {
                Test-ADDnsDiagnostics
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