function Show-ProcessServiceMenu {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Processes & Services                |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Process Information                     |"
        Write-Host "|  [2] Running Processes                       |"
        Write-Host "|  [3] Process Details                         |"
        Write-Host "|  [4] Service Information                     |"
        Write-Host "|  [5] Running Services                        |"
        Write-Host "|  [6] Start Service                           |"
        Write-Host "|  [7] Stop Service                            |"
        Write-Host "|  [8] Restart Service                         |"
        Write-Host "|  [9] Service Dependencies                    |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Get process information
            }

            '2' {
                # Get running processes
            }

            '3' {
                # Get process details
            }

            '4' {
                # Get service information
            }

            '5' {
                # Get running services
            }

            '6' {
                # Start service
            }

            '7' {
                # Stop service
            }

            '8' {
                # Restart service
            }

            '9' {
                # Get service dependencies
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