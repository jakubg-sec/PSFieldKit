function Show-RemoteAdministrationMenu {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {
        Clear-Host

        $CanUseRemote = $Context.IsRemote
        $CanUseSingleRemote = $Context.IsRemote -and -not $Context.IsMultiTarget
        $CanUseMultiRemote = $Context.IsRemote

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Remote Administration               |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        Write-PSFieldKitMenuOption -Number '1' -Text 'Test Remote Connectivity' -Enabled $CanUseRemote
        Write-PSFieldKitMenuOption -Number '2' -Text 'Test WinRM' -Enabled $CanUseRemote
        Write-PSFieldKitMenuOption -Number '3' -Text 'Enter Remote PowerShell' -Enabled $CanUseSingleRemote
        Write-PSFieldKitMenuOption -Number '4' -Text 'Remove PSSession' -Enabled $CanUseSingleRemote
        Write-PSFieldKitMenuOption -Number '5' -Text 'Session Information' -Enabled $CanUseSingleRemote
        Write-PSFieldKitMenuOption -Number '6' -Text 'Invoke Remote Command' -Enabled $CanUseMultiRemote
        Write-PSFieldKitMenuOption -Number '7' -Text 'Invoke Remote Script' -Enabled $CanUseMultiRemote
        Write-PSFieldKitMenuOption -Number '8' -Text 'CIM / WMI Remote Query' -Enabled $CanUseMultiRemote
        Write-PSFieldKitMenuOption -Number '9' -Text 'Remote Computer Management' -Enabled $CanUseSingleRemote
        Write-PSFieldKitMenuOption -Number '10' -Text 'RDP Session Shadowing' -Enabled $CanUseSingleRemote
        Write-PSFieldKitMenuOption -Number '11' -Text 'Remote Reboot / Shutdown' -Enabled $CanUseMultiRemote

        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        if ($Context.IsMultiTarget) {
            Write-Host "`nTarget: Multiple Computers ($($Context.Targets.Count) hosts)" `
                -ForegroundColor Yellow
        }
        else {
            Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow
        }

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseRemote)) {
                    Pause
                    continue
                }

                Test-PSFieldKitConnection -Context $Context
                Pause
            }

            '2' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseRemote)) {
                    Pause
                    continue
                }

                Test-PSFieldKitWinRM -Context $Context
                Pause
            }

            '3' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseSingleRemote)) {
                    Pause
                    continue
                }

                Enter-PSFieldKitRemotePowerShell -Context $Context
                Pause
            }

            '4' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseSingleRemote)) {
                    Pause
                    continue
                }

                Remove-PSFieldKitSession -Context $Context
                Pause
            }

            '5' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseSingleRemote)) {
                    Pause
                    continue
                }

                Get-PSFieldKitSession -Context $Context
                Pause
            }

            '6' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseMultiRemote)) {
                    Pause
                    continue
                }

                Invoke-PSFieldKitCommand -Context $Context
                Pause
            }

            '7' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseMultiRemote)) {
                    Pause
                    continue
                }

                Invoke-PSFieldKitScript -Context $Context
                Pause
            }

            '8' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseMultiRemote)) {
                    Pause
                    continue
                }

                Invoke-PSFieldKitCimQuery -Context $Context
                Pause
            }

            '9' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseSingleRemote)) {
                    Pause
                    continue
                }

                Show-RemoteComputerManagement -Context $Context
            }

            '10' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseSingleRemote)) {
                    Pause
                    continue
                }

                Invoke-PSFieldKitSessionShadowing -Context $Context
                Pause
            }

            '11' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseMultiRemote)) {
                    Pause
                    continue
                }

                Restart-PSFieldKitComputer -Context $Context
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