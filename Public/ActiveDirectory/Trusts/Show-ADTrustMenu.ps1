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
        Write-Host "|  [3] Test Trust                              |"
        Write-Host "|  [4] Forest Trust Information                |"
        Write-Host "|  [5] Trust Diagnostics                       |"
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
                Test-ADTrust
                Pause
            }
            '4' {
                Get-ADForestTrustInformation
                Pause
            }
            '5' {
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