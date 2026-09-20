function Show-PSFieldKitMenu {
    while ($true) {
        Clear-Host

        Write-Host "+------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                  PSFieldKit v1.1.0                   |" -ForegroundColor Cyan
        Write-Host "|              PowerShell SysAdmin Toolkit             |" -ForegroundColor Cyan
        Write-Host "|                    Author: jacob                     |" -ForegroundColor DarkGray
        Write-Host "+------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                                      |"
        Write-Host "|       `"With great power there must also come         |" -ForegroundColor DarkGray
        Write-Host "|                great responsibility.`"                |" -ForegroundColor DarkGray
        Write-Host "|                                                      |"
        Write-Host "+------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                                      |"
        Write-Host "|  SYSTEM                                              |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Computer Information                            |"
        Write-Host "|  [2] Network Diagnostics                             |"
        Write-Host "|  [3] Active Directory                                |"
        Write-Host "|  [4] Processes & Services                            |"
        Write-Host "|  [5] Event Logs                                      |"
        Write-Host "|                                                      |"
        Write-Host "|  ADMINISTRATION                                      |" -ForegroundColor DarkCyan
        Write-Host "|  [6] Storage & Disks                                 |"
        Write-Host "|  [7] Security                                        |"
        Write-Host "|  [8] Remote Administration                           |"
        Write-Host "|  [9] Software & Updates                              |"
        Write-Host "| [10] Security Auditing                               |"
        Write-Host "| [11] Exchange                                        |"
        Write-Host "|                                                      |"
        Write-Host "+------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|  [0] Exit                                            |"
        Write-Host "+------------------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-ComputerMenu -Context $Context
                }
            }

            '2' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-NetworkMenu -Context $Context
                }
            }

            '3' {
                Show-ADMenu
            }

            '4' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-ProcessServiceMenu -Context $Context
                }
            }

            '5' {
                $Context = New-PSFieldKitContext -AllowMultipleTargets

                if ($null -ne $Context) {
                    Show-EventLogMenu -Context $Context
                }
            }

            '6' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-StorageMenu -Context $Context
                }
            }

            '7' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-SecurityMenu -Context $Context
                }
            }

            '8' {
                $Context = New-PSFieldKitContext -AllowMultipleTargets

                if ($null -ne $Context) {
                    Show-RemoteAdministrationMenu -Context $Context
                }
            }

            '9' {
                $Context = New-PSFieldKitContext

                if ($null -ne $Context) {
                    Show-SoftwareMenu -Context $Context
                }
            }

            '10' {
                $Context = New-PSFieldKitContext -AllowMultipleTargets

                if ($null -ne $Context) {
                    Show-SecurityAuditingMenu -Context $Context
                }
            }

            '11' {
                    Show-ExchangeMenu
            }

            '66' {
                Invoke-PSFieldKitOrder66
            }

            '0' {
                Write-Host "`nExiting PSFieldKit..." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                Clear-Host
                Write-Host "`nThank you for using PSFieldKit!" -ForegroundColor Green
                Start-Sleep -Seconds 1
                Clear-Host
                return
            }

            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}