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
        Write-Host "|  [4] PowerShell Events                       |"
        Write-Host "|  [5] Windows Event Channels                  |"
        Write-Host "|  [6] Search Events                           |"
        Write-Host "|  [7] Event Log Information                   |"
        Write-Host "|  [8] Clear Event Log                         |"
        Write-Host "|  [9] Export Event Logs                       |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        if ($Context.IsMultiTarget) {
            Write-Host "`nTarget: Multiple Computers ($($Context.Targets.Count) hosts)" -ForegroundColor Yellow
        }
        else {
            Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow
        }

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Get-SystemEventLog -Context $Context
                Pause
            }

            '2' {
                Get-ApplicationEventLog -Context $Context
                Pause
            }

            '3' {
                Get-SecurityEventLog -Context $Context
                Pause
            }

            '4' {
                Get-PowerShellEventLog -Context $Context
                Pause
            }

            '5' {
                Get-WindowsEventChannels -Context $Context
                Pause
            }

            '6' {
                Search-PSFieldKitEventLog -Context $Context
                Pause
            }

            '7' {
                Get-EventLogInformation -Context $Context
                Pause
            }

            '8' {
                Clear-PSFieldKitEventLog -Context $Context
                Pause
            }

            '9' {
                Export-EventLogs -Context $Context
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