function Show-SecurityMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                Security                      |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Firewall Information                    |"
        Write-Host "|  [2] Local Accounts                          |"
        Write-Host "|  [3] Local Groups                            |"
        Write-Host "|  [4] Security Policy                         |"
        Write-Host "|  [5] Audit Policy                            |"
        Write-Host "|  [6] Certificates                            |"
        Write-Host "|  [7] Microsoft Defender                      |"
        Write-Host "|  [8] BitLocker                               |"
        Write-Host "|  [9] Logged-on Users                         |"
        Write-Host "| [10] Security Events                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Get-FirewallInformation
            }

            '2' {
                # Get-LocalAccounts
            }

            '3' {
                # Get-LocalGroups
            }

            '4' {
                # Get-SecurityPolicy
            }

            '5' {
                # Get-AuditPolicy
            }

            '6' {
                # Get-Certificates
            }

            '7' {
                # Get-DefenderStatus
            }

            '8' {
                # Get-BitLockerStatus
            }

            '9' {
                # Get-LoggedOnUsers
            }

            '10' {
                # Get-SecurityEvents
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