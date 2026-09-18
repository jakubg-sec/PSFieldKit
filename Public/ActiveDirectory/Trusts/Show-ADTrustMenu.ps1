function Show-ADTrustMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                  AD Trusts                   |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Trust Information                       |"
        Write-Host "|  [2] List Domain Trusts                      |"
        Write-Host "|  [3] Trust Details                           |"
        Write-Host "|  [4] Trust Direction                         |"
        Write-Host "|  [5] Trust Attributes                        |"
        Write-Host "|  [6] Test Trust                              |"
        Write-Host "|  [7] Forest Trust Information                |"
        Write-Host "|  [8] Trust Diagnostics                       |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADTrustInformation
                Pause
            }

            '2' {
                Get-ADDomainTrusts
                Pause
            }

            '3' {
                Get-ADTrustDetails
                Pause
            }

            '4' {
                Get-ADTrustDirection
                Pause
            }

            '5' {
                Get-ADTrustAttributes
                Pause
            }

            '6' {
                Test-ADTrust
                Pause
            }

            '7' {
                Get-ADForestTrustInformation
                Pause
            }

            '8' {
                Test-ADTrustDiagnostics
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