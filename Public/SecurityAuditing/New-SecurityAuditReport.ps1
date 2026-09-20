function New-SecurityAuditReport {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $HoursInput = Read-Host "Enter analysis window in hours (default: 24)"

    if ([string]::IsNullOrWhiteSpace($HoursInput)) {

        $Hours = 24
    }
    elseif (-not [int]::TryParse($HoursInput, [ref]$Hours)) {

        Write-Host "`nInvalid number of hours." -ForegroundColor Red
        return
    }
    elseif ($Hours -lt 1 -or $Hours -gt 720) {

        Write-Host "`nAnalysis window must be between 1 and 720 hours." -ForegroundColor Red
        return
    }

    $DefaultFileName = "PSFieldKit-SecurityAudit-$(
        Get-Date -Format 'yyyyMMdd-HHmmss'
    ).txt"

    $OutputPath = Read-Host "Enter report path (default: $DefaultFileName)"

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {

        $OutputPath = Join-Path `
            -Path (Get-Location) `
            -ChildPath $DefaultFileName
    }

    try {

        $OutputDirectory = Split-Path `
            -Path $OutputPath `
            -Parent

        if (
            -not [string]::IsNullOrWhiteSpace($OutputDirectory) -and
            -not (Test-Path -Path $OutputDirectory)
        ) {

            New-Item `
                -Path $OutputDirectory `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        $ScriptBlock = {

            param(
                [int]$Hours
            )

            $Since = (Get-Date).AddHours(-$Hours)

            #
            # Security Event Log
            #

            $SecurityLog = Get-WinEvent `
                -ListLog 'Security' `
                -ErrorAction Stop

            $SecurityEvents = @(
                Get-WinEvent `
                    -FilterHashtable @{
                        LogName   = 'Security'
                        StartTime = $Since
                        Id        = 4624,
                            4625,
                            4672,
                            4688,
                            4719,
                            4728,
                            4729,
                            4732,
                            4733,
                            4740,
                            4756,
                            4757,
                            1102
                    } `
                    -MaxEvents 10000 `
                    -ErrorAction SilentlyContinue
            )

            #
            # PowerShell Operational Log
            #

            $PowerShellEvents = @(
                Get-WinEvent `
                    -FilterHashtable @{
                        LogName   = 'Microsoft-Windows-PowerShell/Operational'
                        StartTime = $Since
                        Id        = 4103, 4104
                    } `
                    -MaxEvents 5000 `
                    -ErrorAction SilentlyContinue
            )

            #
            # Firewall
            #

            $FirewallProfiles = @(
                Get-NetFirewallProfile `
                    -ErrorAction SilentlyContinue
            )

            #
            # Defender
            #

            $DefenderStatus = $null

            try {

                $DefenderStatus = Get-MpComputerStatus `
                    -ErrorAction Stop
            }
            catch {

                $DefenderStatus = $null
            }

            #
            # PowerShell Logging Configuration
            #

            $ScriptBlockLogging = Get-ItemProperty `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
                -Name 'EnableScriptBlockLogging' `
                -ErrorAction SilentlyContinue

            $ModuleLogging = Get-ItemProperty `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' `
                -Name 'EnableModuleLogging' `
                -ErrorAction SilentlyContinue

            $Transcription = Get-ItemProperty `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' `
                -Name 'EnableTranscripting' `
                -ErrorAction SilentlyContinue

            #
            # Reboot Pending
            #

            $CBSRebootPending = Test-Path `
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

            $WindowsUpdateRebootRequired = Test-Path `
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'

            $PendingFileRenameOperations = Get-ItemProperty `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
                -Name 'PendingFileRenameOperations' `
                -ErrorAction SilentlyContinue

            $PendingRename = (
                $null -ne $PendingFileRenameOperations.PendingFileRenameOperations -and
                $PendingFileRenameOperations.PendingFileRenameOperations.Count -gt 0
            )

            #
            # Event Counts
            #
            # Use PSCustomObject instead of OrderedDictionary.
            # This is safe across Invoke-Command / PowerShell remoting.
            #

            $EventCounts = [PSCustomObject]@{

                SuccessfulLogons = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4624
                    }
                ).Count

                FailedLogons = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4625
                    }
                ).Count

                SpecialPrivileges = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4672
                    }
                ).Count

                ProcessCreation = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4688
                    }
                ).Count

                AuditPolicyChanges = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4719
                    }
                ).Count

                GlobalGroupChanges = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -in @(4728, 4729)
                    }
                ).Count

                LocalGroupChanges = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -in @(4732, 4733)
                    }
                ).Count

                AccountLockouts = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 4740
                    }
                ).Count

                UniversalGroupChanges = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -in @(4756, 4757)
                    }
                ).Count

                SecurityLogClears = @(
                    $SecurityEvents |
                    Where-Object {
                        $_.Id -eq 1102
                    }
                ).Count

                ModuleLoggingEvents = @(
                    $PowerShellEvents |
                    Where-Object {
                        $_.Id -eq 4103
                    }
                ).Count

                ScriptBlockLoggingEvents = @(
                    $PowerShellEvents |
                    Where-Object {
                        $_.Id -eq 4104
                    }
                ).Count
            }

            #
            # Persistence
            #

            $ScheduledTasks = @(
                Get-ScheduledTask `
                    -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.State -ne 'Disabled'
                }
            )

            $AutoStartServices = @(
                Get-CimInstance `
                    -ClassName Win32_Service `
                    -Filter "StartMode = 'Auto'" `
                    -ErrorAction SilentlyContinue
            )

            $StartupCommands = @(
                Get-CimInstance `
                    -ClassName Win32_StartupCommand `
                    -ErrorAction SilentlyContinue
            )

            $WmiFilters = @(
                Get-CimInstance `
                    -Namespace 'root\subscription' `
                    -ClassName __EventFilter `
                    -ErrorAction SilentlyContinue
            )

            #
            # PowerShell Operational Log Status
            #

            $PowerShellOperationalLog = Get-WinEvent `
                -ListLog 'Microsoft-Windows-PowerShell/Operational' `
                -ErrorAction SilentlyContinue

            #
            # Audit Policy
            #

            $AuditPolPath = "$env:SystemRoot\System32\auditpol.exe"

            $AuditPolicy = @()

            if (Test-Path -Path $AuditPolPath) {

                $AuditOutput = @(
                    & $AuditPolPath /get /category:* 2>&1
                )

                $AuditPolicy = @(
                    $AuditOutput |
                    Where-Object {
                        $_ -match '^\s{2,}.+\s{2,}.+'
                    }
                )
            }

            #
            # Failed Logons by Source
            #

            $FailedLogons = @(
                $SecurityEvents |
                Where-Object {
                    $_.Id -eq 4625
                }
            )

            $FailedLogonsBySource = @(
                $FailedLogons |
                Group-Object {
                    try {

                        $Xml = [xml]$_.ToXml()

                        $IpAddressNode = $Xml.Event.EventData.Data |
                            Where-Object {
                                $_.Name -eq 'IpAddress'
                            } |
                            Select-Object -First 1

                        if ($null -ne $IpAddressNode -and
                            -not [string]::IsNullOrWhiteSpace(
                                [string]$IpAddressNode.'#text'
                            )
                        ) {

                            [string]$IpAddressNode.'#text'
                        }
                        else {

                            'Unknown'
                        }
                    }
                    catch {

                        'Unknown'
                    }
                } |
                Sort-Object Count -Descending |
                Select-Object -First 10 `
                    @{Name = 'Source'; Expression = { $_.Name }},
                    Count
            )

            #
            # Firewall Status
            #

            $FirewallEnabled = if ($FirewallProfiles.Count -gt 0) {

                @(
                    $FirewallProfiles |
                    Where-Object {
                        -not $_.Enabled
                    }
                ).Count -eq 0
            }
            else {

                $false
            }

            #
            # Return a remoting-safe object
            #

            [PSCustomObject]@{

                SecurityLogEnabled = [bool]$SecurityLog.IsEnabled

                SecurityLogRecords = $SecurityLog.RecordCount

                SecurityLogSizeMB = [math]::Round(
                    $SecurityLog.MaximumSizeInBytes / 1MB,
                    2
                )

                PowerShellOperationalLogEnabled = if (
                    $null -ne $PowerShellOperationalLog
                ) {

                    [bool]$PowerShellOperationalLog.IsEnabled
                }
                else {

                    $false
                }

                ScriptBlockLogging = (
                    $null -ne $ScriptBlockLogging.EnableScriptBlockLogging -and
                    $ScriptBlockLogging.EnableScriptBlockLogging -eq 1
                )

                ModuleLogging = (
                    $null -ne $ModuleLogging.EnableModuleLogging -and
                    $ModuleLogging.EnableModuleLogging -eq 1
                )

                Transcription = (
                    $null -ne $Transcription.EnableTranscripting -and
                    $Transcription.EnableTranscripting -eq 1
                )

                FirewallEnabled = $FirewallEnabled

                DefenderAvailable = (
                    $null -ne $DefenderStatus
                )

                DefenderRealTimeProtection = if (
                    $null -ne $DefenderStatus
                ) {

                    $DefenderStatus.RealTimeProtectionEnabled
                }
                else {

                    $null
                }

                RebootPending = (
                    $CBSRebootPending -or
                    $WindowsUpdateRebootRequired -or
                    $PendingRename
                )

                EventCounts = $EventCounts

                ScheduledTasks = $ScheduledTasks.Count

                AutoStartServices = $AutoStartServices.Count

                StartupCommands = $StartupCommands.Count

                WmiEventFilters = $WmiFilters.Count

                AuditPolicy = @($AuditPolicy)

                FailedLogonsBySource = @(
                    $FailedLogonsBySource
                )
            }
        }

        #
        # Report Buffer
        #

        $Report = New-Object System.Collections.Generic.List[string]

        $Report.Add('==============================================================')
        $Report.Add('                    PSFieldKit Security Audit')
        $Report.Add('==============================================================')
        $Report.Add('')

        $Report.Add(
            "Generated      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        )

        $Report.Add("Author         : jacob")
        $Report.Add("Analysis Window: $Hours hour(s)")
        $Report.Add('')

        #
        # Process Targets
        #

        foreach ($Target in $Context.Targets) {

            if ($Context.Targets.Count -gt 1) {

                $TargetLabel = $Target.ComputerName
            }
            else {

                $TargetLabel = $Context.ComputerName
            }

            Write-Host `
                "`nCollecting security audit data from $TargetLabel..." `
                -ForegroundColor Cyan

            try {

                if ($Target.IsRemote) {

                    $Result = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ArgumentList $Hours `
                        -ErrorAction Stop
                }
                else {

                    $Result = & $ScriptBlock $Hours
                }

                #
                # Target Header
                #

                $Report.Add(
                    '--------------------------------------------------------------'
                )

                $Report.Add(
                    "TARGET: $TargetLabel"
                )

                $Report.Add(
                    '--------------------------------------------------------------'
                )

                $Report.Add('')

                #
                # System Security Status
                #

                $Report.Add('SYSTEM SECURITY STATUS')
                $Report.Add('----------------------')

                $Report.Add(
                    "Security Event Log       : $($Result.SecurityLogEnabled)"
                )

                $Report.Add(
                    "Security Log Records     : $($Result.SecurityLogRecords)"
                )

                $Report.Add(
                    "Security Log Size        : $($Result.SecurityLogSizeMB) MB"
                )

                $Report.Add(
                    "Windows Firewall         : $($Result.FirewallEnabled)"
                )

                $Report.Add(
                    "Defender Available       : $($Result.DefenderAvailable)"
                )

                $Report.Add(
                    "Defender Real-Time       : $($Result.DefenderRealTimeProtection)"
                )

                $Report.Add(
                    "Reboot Pending           : $($Result.RebootPending)"
                )

                $Report.Add('')

                #
                # PowerShell Logging
                #

                $Report.Add('POWERSHELL LOGGING')
                $Report.Add('------------------')

                $Report.Add(
                    "Operational Log          : $($Result.PowerShellOperationalLogEnabled)"
                )

                $Report.Add(
                    "Script Block Logging     : $($Result.ScriptBlockLogging)"
                )

                $Report.Add(
                    "Module Logging           : $($Result.ModuleLogging)"
                )

                $Report.Add(
                    "Transcription            : $($Result.Transcription)"
                )

                $Report.Add('')

                #
                # Security Event Summary
                #

                $Report.Add('SECURITY EVENT SUMMARY')
                $Report.Add('----------------------')

                $Report.Add(
                    "Successful Logons        : $($Result.EventCounts.SuccessfulLogons)"
                )

                $Report.Add(
                    "Failed Logons            : $($Result.EventCounts.FailedLogons)"
                )

                $Report.Add(
                    "Special Privileges       : $($Result.EventCounts.SpecialPrivileges)"
                )

                $Report.Add(
                    "Process Creation         : $($Result.EventCounts.ProcessCreation)"
                )

                $Report.Add(
                    "Audit Policy Changes     : $($Result.EventCounts.AuditPolicyChanges)"
                )

                $Report.Add(
                    "Global Group Changes     : $($Result.EventCounts.GlobalGroupChanges)"
                )

                $Report.Add(
                    "Local Group Changes      : $($Result.EventCounts.LocalGroupChanges)"
                )

                $Report.Add(
                    "Account Lockouts         : $($Result.EventCounts.AccountLockouts)"
                )

                $Report.Add(
                    "Universal Group Changes  : $($Result.EventCounts.UniversalGroupChanges)"
                )

                $Report.Add(
                    "Security Log Clears      : $($Result.EventCounts.SecurityLogClears)"
                )

                $Report.Add('')

                #
                # PowerShell Activity
                #

                $Report.Add('POWERSHELL ACTIVITY')
                $Report.Add('-------------------')

                $Report.Add(
                    "Module Logging Events    : $($Result.EventCounts.ModuleLoggingEvents)"
                )

                $Report.Add(
                    "Script Block Events      : $($Result.EventCounts.ScriptBlockLoggingEvents)"
                )

                $Report.Add('')

                #
                # Persistence Overview
                #

                $Report.Add('PERSISTENCE OVERVIEW')
                $Report.Add('--------------------')

                $Report.Add(
                    "Scheduled Tasks          : $($Result.ScheduledTasks)"
                )

                $Report.Add(
                    "Auto-Start Services      : $($Result.AutoStartServices)"
                )

                $Report.Add(
                    "Startup Commands         : $($Result.StartupCommands)"
                )

                $Report.Add(
                    "WMI Event Filters        : $($Result.WmiEventFilters)"
                )

                $Report.Add('')

                #
                # Failed Logons by Source
                #

                $Report.Add('FAILED LOGONS BY SOURCE')
                $Report.Add('-----------------------')

                if ($Result.FailedLogonsBySource.Count -eq 0) {

                    $Report.Add(
                        'No failed logon sources found.'
                    )
                }
                else {

                    foreach ($Source in $Result.FailedLogonsBySource) {

                        $SourceName = [string]$Source.Source
                        $SourceCount = [int]$Source.Count

                        #
                        # Evaluate -f BEFORE calling List.Add().
                        #

                        $FormattedSource = "{0,-35} {1,6}" -f `
                            $SourceName,
                            $SourceCount

                        $Report.Add(
                            $FormattedSource
                        )
                    }
                }

                $Report.Add('')

                #
                # Audit Policy
                #

                $Report.Add('AUDIT POLICY')
                $Report.Add('------------')

                if ($Result.AuditPolicy.Count -eq 0) {

                    $Report.Add(
                        'Audit policy information unavailable.'
                    )
                }
                else {

                    foreach ($Line in $Result.AuditPolicy) {

                        $Report.Add(
                            [string]$Line
                        )
                    }
                }

                $Report.Add('')
            }
            catch {

                $Report.Add('ERROR')
                $Report.Add('-----')
                $Report.Add(
                    $_.Exception.Message
                )
                $Report.Add('')
            }
        }

        #
        # Report Footer
        #

        $Report.Add(
            '=============================================================='
        )

        $Report.Add(
            '                    End of Security Audit'
        )

        $Report.Add(
            '=============================================================='
        )

        $Report |
            Set-Content `
                -Path $OutputPath `
                -Encoding UTF8 `
                -ErrorAction Stop

        Write-Host `
            "`nSecurity report generated successfully." `
            -ForegroundColor Green

        Write-Host `
            "Path: $OutputPath" `
            -ForegroundColor Cyan
    }
    catch {

        Write-Host `
            "`nFailed to generate security audit report." `
            -ForegroundColor Red

        Write-Host `
            $_.Exception.Message `
            -ForegroundColor Yellow
    }
}