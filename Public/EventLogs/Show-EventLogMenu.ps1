function Show-EventLogMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|               Event Logs                     |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] System Events                           |"
        Write-Host "|  [2] Application Events                      |"
        Write-Host "|  [3] Security Events                         |"
        Write-Host "|  [4] Windows PowerShell Events               |"
        Write-Host "|  [5] Microsoft-Windows Events                |"
        Write-Host "|  [6] Search Events                           |"
        Write-Host "|  [7] Export Event Logs                       |"
        Write-Host "|  [8] Clear Event Logs                        |"
        Write-Host "|  [9] Event Log Configuration                 |"
        Write-Host "| [10] Export Logs                             |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Get-SystemEventLog
            }

            '2' {
                # Get-ApplicationEventLog
            }

            '3' {
                # Get-SecurityEventLog
            }

            '4' {
                # Get-PowerShellEventLog
            }

            '5' {
                # Get-WindowsEventLog
            }

            '6' {
                # Search-EventLog
            }

            '7' {
                # Export-EventLog
            }

            '8' {
                # Clear-EventLog
            }

            '9' {
                # Get-EventLogConfiguration
            }
            
            '10' {
                # Export-EventLogsArchive
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