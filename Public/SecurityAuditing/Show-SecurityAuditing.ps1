function Show-SecurityAuditingMenu {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {
        Clear-Host

        $CanUseArchivedLog = -not $Context.IsRemote -and -not $Context.IsMultiTarget

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|            Security Auditing                 |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        Write-PSFieldKitMenuOption -Number '1' -Text 'Security Audit Overview' -Enabled $false
        Write-PSFieldKitMenuOption -Number '2' -Text 'Suspicious Activity Analysis' -Enabled $false
        Write-PSFieldKitMenuOption -Number '3' -Text 'Authentication Audit' -Enabled $false
        Write-PSFieldKitMenuOption -Number '4' -Text 'Privileged Account Activity' -Enabled $false
        Write-PSFieldKitMenuOption -Number '5' -Text 'Persistence & Autoruns Audit' -Enabled $false
        Write-PSFieldKitMenuOption -Number '6' -Text 'PowerShell Activity Audit' -Enabled $false
        Write-PSFieldKitMenuOption -Number '7' -Text 'Audit Policy & Logging Check' -Enabled $false
        Write-PSFieldKitMenuOption -Number '8' -Text 'Generate Security Report' -Enabled $false
        Write-PSFieldKitMenuOption -Number '9' -Text 'Analyze Archived Event Log' -Enabled $false

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
                Get-SecurityAuditOverview -Context $Context
                Pause
            }

            '2' {
                Find-SuspiciousActivity -Context $Context
                Pause
            }

            '3' {
                Get-AuthenticationAudit -Context $Context
                Pause
            }

            '4' {
                Get-PrivilegedAccountActivity -Context $Context
                Pause
            }

            '5' {
                Get-PersistenceAudit -Context $Context
                Pause
            }

            '6' {
                Get-PowerShellActivityAudit -Context $Context
                Pause
            }

            '7' {
                Get-AuditPolicyStatus -Context $Context
                Pause
            }

            '8' {
                New-SecurityAuditReport -Context $Context
                Pause
            }

            '9' {
                if (-not (Test-PSFieldKitMenuOption -Available $CanUseArchivedLog)) {
                    Pause
                    continue
                }

                Get-ArchivedEventLogAnalysis -Context $Context
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