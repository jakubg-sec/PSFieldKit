function Show-ADGPOMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                Group Policy                  |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] GPO Information                         |"
        Write-Host "|  [2] Search GPOs                             |"
        Write-Host "|  [3] GPO Links                               |"
        Write-Host "|  [4] GPO Permissions                         |"
        Write-Host "|  [5] Generate GPReport                       |"
        Write-Host "|  [6] Force GPUpdate                          |"
        Write-Host "|  [7] Group Policy Results                    |"
        Write-Host "|  [8] Group Policy Modeling                   |"
        Write-Host "|  [9] GPO Diagnostics                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADGPOInformation
                Pause
            }

            '2' {
                Search-ADGPOs
                Pause
            }

            '3' {
                Get-ADGPOLinks
                Pause
            }

            '4' {
                Get-ADGPOPermissions
                Pause
            }

            '5' {
                Get-ADGPReport
                Pause
            }

            '6' {
                Invoke-ADGPUpdate
                Pause
            }

            '7' {
                Get-ADGroupPolicyResults
                Pause
            }

            '8' {
                Get-ADGroupPolicyModeling
                Pause
            }

            '9' {
                Test-ADGPODiagnostics
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