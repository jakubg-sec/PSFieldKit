function Get-SecurityAuditOverview {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        Write-Host "`nSecurity Audit Overview" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                $Result = Invoke-Command -ComputerName $Target.ComputerName -ScriptBlock {
                    $Now = Get-Date
                    $StartTime = $Now.AddHours(-24)

                    $SecurityLog = Get-WinEvent -ListLog 'Security' -ErrorAction Stop
                    $PowerShellLog = Get-WinEvent -ListLog 'Microsoft-Windows-PowerShell/Operational' -ErrorAction SilentlyContinue

                    $ScriptBlockLogging = Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -ErrorAction SilentlyContinue
                    $ModuleLogging = Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -ErrorAction SilentlyContinue
                    $Transcription = Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription' -ErrorAction SilentlyContinue

                    $FirewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
                    $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

                    $SecurityEvt = @(
                        Get-WinEvent -FilterHashtable @{
                            LogName = 'Security'
                            Id = 4624,4625,4672,4688,4719,4720,4732,4738
                            StartTime = $StartTime
                            EndTime = $Now
                        } -ErrorAction SilentlyContinue
                    )

                    $EvtCounts = [ordered]@{
                        '4624 Successful Logon'       = @($SecurityEvt | Where-Object Id -eq 4624).Count
                        '4625 Failed Logon'           = @($SecurityEvt | Where-Object Id -eq 4625).Count
                        '4672 Special Privileges'     = @($SecurityEvt | Where-Object Id -eq 4672).Count
                        '4688 Process Creation'       = @($SecurityEvt | Where-Object Id -eq 4688).Count
                        '4719 Audit Policy Changed'   = @($SecurityEvt | Where-Object Id -eq 4719).Count
                        '4720 Account Created'        = @($SecurityEvt | Where-Object Id -eq 4720).Count
                        '4732 Local Group Member Added' = @($SecurityEvt | Where-Object Id -eq 4732).Count
                        '4738 Account Changed'        = @($SecurityEvt | Where-Object Id -eq 4738).Count
                    }

                    $AuditReadiness = [PSCustomObject]@{
                        SecurityLogEnabled       = $SecurityLog.IsEnabled
                        SecurityLogRecordCount  = $SecurityLog.RecordCount
                        SecurityLogMaxSizeMB    = [math]::Round($SecurityLog.MaximumSizeInBytes / 1MB, 2)
                        PowerShellLogEnabled    = if ($PowerShellLog) { $PowerShellLog.IsEnabled } else { $false }
                        ScriptBlockLogging      = [bool]$ScriptBlockLogging.EnableScriptBlockLogging
                        ModuleLogging           = [bool]$ModuleLogging.EnableModuleLogging
                        Transcription           = [bool]$Transcription.EnableTranscripting
                        FirewallProfilesEnabled = @($FirewallProfiles | Where-Object Enabled).Count
                        DefenderEnabled         = if ($DefenderStatus) { [bool]$DefenderStatus.AntivirusEnabled } else { $false }
                        RealTimeProtection      = if ($DefenderStatus) { [bool]$DefenderStatus.RealTimeProtectionEnabled } else { $false }
                    }

                    [PSCustomObject]@{
                        Host = $env:COMPUTERNAME
                        AuditReadiness = $AuditReadiness
                        EventCounts = $EvtCounts
                        SecurityLog = $SecurityLog
                        PowerShellLog = $PowerShellLog
                    }
                } -ErrorAction Stop

                Write-Host "`nAudit Readiness" -ForegroundColor Cyan
                Write-Host "---------------" -ForegroundColor DarkCyan

                Write-Host "Security Log Enabled       : $($Result.AuditReadiness.SecurityLogEnabled)"
                Write-Host "Security Log Records      : $($Result.AuditReadiness.SecurityLogRecordCount)"
                Write-Host "Security Log Size         : $($Result.AuditReadiness.SecurityLogMaxSizeMB) MB"
                Write-Host "PowerShell Log Enabled    : $($Result.AuditReadiness.PowerShellLogEnabled)"
                Write-Host "Script Block Logging      : $($Result.AuditReadiness.ScriptBlockLogging)"
                Write-Host "Module Logging            : $($Result.AuditReadiness.ModuleLogging)"
                Write-Host "PowerShell Transcription : $($Result.AuditReadiness.Transcription)"
                Write-Host "Firewall Profiles Enabled : $($Result.AuditReadiness.FirewallProfilesEnabled)"
                Write-Host "Defender Enabled          : $($Result.AuditReadiness.DefenderEnabled)"
                Write-Host "Real-Time Protection      : $($Result.AuditReadiness.RealTimeProtection)"

                Write-Host "`nSecurity Events - Last 24 Hours" -ForegroundColor Cyan
                Write-Host "--------------------------------" -ForegroundColor DarkCyan

                foreach ($EvtName in $Result.EventCounts.Keys) {
                    $EvtCount = $Result.EventCounts[$EvtName]

                    if ($EvtCount -gt 0) {
                        Write-Host ("{0,-34} : {1}" -f $EvtName, $EvtCount)
                    }
                    else {
                        Write-Host ("{0,-34} : {1}" -f $EvtName, $EvtCount) -ForegroundColor DarkGray
                    }
                }
            }
            catch {
                Write-Host "Failed to retrieve security audit overview." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nSecurity audit overview failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}