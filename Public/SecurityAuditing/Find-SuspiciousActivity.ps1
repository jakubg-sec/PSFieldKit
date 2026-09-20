function Find-SuspiciousActivity {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    $HoursInput = Read-Host "Enter analysis window in hours (default: 24)"
    if ([string]::IsNullOrWhiteSpace($HoursInput)) {
        $Hours = 24
    }
    elseif ([int]::TryParse($HoursInput, [ref]$Hours)) {
        if ($Hours -lt 1) {
            $Hours = 24
        }
        elseif ($Hours -gt 720) {
            $Hours = 720
        }
    }
    else {
        $Hours = 24
    }
    Write-Host "`nSuspicious Activity Analysis" -ForegroundColor Cyan
    Write-Host "----------------------------" -ForegroundColor DarkCyan
    Write-Host "Analysis window: $Hours hour(s)"
    $AnalysisScript = {
        param(
            [int]$AnalysisHours
        )
        $Now = Get-Date
        $StartTime = $Now.AddHours(-$AnalysisHours)
        $SecurityEvt = @(
            Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                Id = 4625,4698,4719,4720,4728,4732,4740,4756
                StartTime = $StartTime
                EndTime = $Now
            } -ErrorAction SilentlyContinue
        )
        $SecurityProcessEvt = @(
            Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                Id = 4688
                StartTime = $StartTime
                EndTime = $Now
            } -ErrorAction SilentlyContinue
        )
        $SystemEvt = @(
            Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                Id = 7045
                StartTime = $StartTime
                EndTime = $Now
            } -ErrorAction SilentlyContinue
        )
        $PowerShellEvt = @(
            Get-WinEvent -FilterHashtable @{
                LogName = 'Microsoft-Windows-PowerShell/Operational'
                Id = 4104
                StartTime = $StartTime
                EndTime = $Now
            } -ErrorAction SilentlyContinue
        )
        $Findings = [System.Collections.Generic.List[object]]::new()
        $FailedLogons = @(
            $SecurityEvt |
            Where-Object { $_.Id -eq 4625 } |
            ForEach-Object {
                $EvtXml = [xml]$_.ToXml()
                $SourceIp = ($EvtXml.Event.EventData.Data | Where-Object { $_.Name -eq 'IpAddress' }).'#text'
                $TargetUser = ($EvtXml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
                [PSCustomObject]@{
                    TimeCreated = $_.TimeCreated
                    SourceIp = $SourceIp
                    TargetUser = $TargetUser
                    Message = $_.Message
                }
            }
        )
        $FailedLogonGroups = @(
            $FailedLogons |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.SourceIp) -and
                $_.SourceIp -notin @('-', '127.0.0.1', '::1')
            } |
            Group-Object SourceIp |
            Sort-Object Count -Descending
        )
        foreach ($Group in $FailedLogonGroups) {
            if ($Group.Count -ge 25) {
                $null = $Findings.Add(
                    [PSCustomObject]@{
                        Severity = 'High'
                        Category = 'Authentication'
                        Time = ($Group.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                        Source = $Group.Name
                        Details = "Multiple failed logons detected: $($Group.Count) attempts."
                    }
                )
            }
            elseif ($Group.Count -ge 10) {
                $null = $Findings.Add(
                    [PSCustomObject]@{
                        Severity = 'Medium'
                        Category = 'Authentication'
                        Time = ($Group.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                        Source = $Group.Name
                        Details = "Repeated failed logons detected: $($Group.Count) attempts."
                    }
                )
            }
        }
        foreach ($Evt in $SecurityEvt) {
            switch ($Evt.Id) {
                4719 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Audit Policy'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'Audit policy was changed.'
                        }
                    )
                }
                4720 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Account'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A new user account was created.'
                        }
                    )
                }
                4740 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'Medium'
                            Category = 'Account'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A user account was locked out.'
                        }
                    )
                }
                4728 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Group Membership'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A member was added to a security-enabled global group.'
                        }
                    )
                }
                4732 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Group Membership'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A member was added to a security-enabled local group.'
                        }
                    )
                }
                4756 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Group Membership'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A member was added to a security-enabled universal group.'
                        }
                    )
                }
                4698 {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'Medium'
                            Category = 'Scheduled Task'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = 'A scheduled task was created.'
                        }
                    )
                }
            }
        }
        foreach ($Evt in $SystemEvt) {
            $Message = $Evt.Message
            $SuspiciousPattern = $false
            if ($Message -match '(?i)\\AppData\\|\\Temp\\|powershell|cmd\.exe|wscript|cscript|mshta|rundll32|regsvr32|certutil|bitsadmin|base64|downloadstring|invoke-webrequest|frombase64string') {
                $SuspiciousPattern = $true
            }
            if ($SuspiciousPattern) {
                $null = $Findings.Add(
                    [PSCustomObject]@{
                        Severity = 'High'
                        Category = 'Service Installation'
                        Time = $Evt.TimeCreated
                        Source = 'System'
                        Details = "Service installation with potentially suspicious command or path detected. $($Message -replace '\r?\n', ' ')"
                    }
                )
            }
            else {
                $null = $Findings.Add(
                    [PSCustomObject]@{
                        Severity = 'Medium'
                        Category = 'Service Installation'
                        Time = $Evt.TimeCreated
                        Source = 'System'
                        Details = 'A new Windows service was installed.'
                    }
                )
            }
        }
        foreach ($Evt in $PowerShellEvt) {
            $Message = $Evt.Message
            if ($Message -match '(?i)EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|Reflection|Add-Type|-WindowStyle\s+Hidden|\bHidden\b') {
                $null = $Findings.Add(
                    [PSCustomObject]@{
                        Severity = 'High'
                        Category = 'PowerShell'
                        Time = $Evt.TimeCreated
                        Source = 'PowerShell Operational'
                        Details = "Potentially suspicious PowerShell activity detected. $($Message -replace '\r?\n', ' ')"
                    }
                )
            }
        }
        foreach ($Evt in $SecurityProcessEvt) {
            $Message = $Evt.Message
            if ($Message -match '(?i)powershell(\.exe)?|cmd(\.exe)?|wscript(\.exe)?|cscript(\.exe)?|mshta(\.exe)?|rundll32(\.exe)?|regsvr32(\.exe)?|certutil(\.exe)?|bitsadmin(\.exe)?') {
                if ($Message -match '(?i)EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|-WindowStyle\s+Hidden|\bHidden\b') {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'High'
                            Category = 'Process Creation'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = "Potentially suspicious process creation detected. $($Message -replace '\r?\n', ' ')"
                        }
                    )
                }
                else {
                    $null = $Findings.Add(
                        [PSCustomObject]@{
                            Severity = 'Medium'
                            Category = 'Process Creation'
                            Time = $Evt.TimeCreated
                            Source = 'Security'
                            Details = "Administrative or scripting process created. $($Message -replace '\r?\n', ' ')"
                        }
                    )
                }
            }
        }
        if ($Findings.Count -eq 0) {
            [PSCustomObject]@{
                Host = $env:COMPUTERNAME
                AnalysisHours = $AnalysisHours
                Findings = @()
                FailedLogons = $FailedLogons.Count
                EventLogClearCount = 0
                AuditPolicyChangeCount = @($SecurityEvt | Where-Object { $_.Id -eq 4719 }).Count
                NewAccountCount = @($SecurityEvt | Where-Object { $_.Id -eq 4720 }).Count
                AccountLockoutCount = @($SecurityEvt | Where-Object { $_.Id -eq 4740 }).Count
                GroupMembershipChangeCount = @($SecurityEvt | Where-Object { $_.Id -in @(4728,4732,4756) }).Count
                ScheduledTaskCount = @($SecurityEvt | Where-Object { $_.Id -eq 4698 }).Count
                ServiceInstallCount = $SystemEvt.Count
                SuspiciousPowerShellCount = @(
                    $PowerShellEvt |
                    Where-Object {
                        $_.Message -match '(?i)EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|Reflection|Add-Type|-WindowStyle\s+Hidden|\bHidden\b'
                    }
                ).Count
                SuspiciousProcessCount = @(
                    $SecurityProcessEvt |
                    Where-Object {
                        $_.Message -match '(?i)(EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|-WindowStyle\s+Hidden|\bHidden\b)' -and
                        $_.Message -match '(?i)powershell(\.exe)?|cmd(\.exe)?|wscript(\.exe)?|cscript(\.exe)?|mshta(\.exe)?|rundll32(\.exe)?|regsvr32(\.exe)?|certutil(\.exe)?|bitsadmin(\.exe)?'
                    }
                ).Count
            }
            return
        }
        [PSCustomObject]@{
            Host = $env:COMPUTERNAME
            AnalysisHours = $AnalysisHours
            Findings = $Findings.ToArray()
            FailedLogons = $FailedLogons.Count
            EventLogClearCount = 0
            AuditPolicyChangeCount = @($SecurityEvt | Where-Object { $_.Id -eq 4719 }).Count
            NewAccountCount = @($SecurityEvt | Where-Object { $_.Id -eq 4720 }).Count
            AccountLockoutCount = @($SecurityEvt | Where-Object { $_.Id -eq 4740 }).Count
            GroupMembershipChangeCount = @($SecurityEvt | Where-Object { $_.Id -in @(4728,4732,4756) }).Count
            ScheduledTaskCount = @($SecurityEvt | Where-Object { $_.Id -eq 4698 }).Count
            ServiceInstallCount = $SystemEvt.Count
            SuspiciousPowerShellCount = @(
                $PowerShellEvt |
                Where-Object {
                    $_.Message -match '(?i)EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|Reflection|Add-Type|-WindowStyle\s+Hidden|\bHidden\b'
                }
            ).Count
            SuspiciousProcessCount = @(
                $SecurityProcessEvt |
                Where-Object {
                    $_.Message -match '(?i)(EncodedCommand|FromBase64String|DownloadString|Invoke-WebRequest|Invoke-Expression|\bIEX\b|-WindowStyle\s+Hidden|\bHidden\b)' -and
                    $_.Message -match '(?i)powershell(\.exe)?|cmd(\.exe)?|wscript(\.exe)?|cscript(\.exe)?|mshta(\.exe)?|rundll32(\.exe)?|regsvr32(\.exe)?|certutil(\.exe)?|bitsadmin(\.exe)?'
                }
            ).Count
        }
    }
    foreach ($Target in $Context.Targets) {
        Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow
        try {
            if ($Target.IsRemote) {
                $Result = Invoke-Command -ComputerName $Target.ComputerName -ScriptBlock $AnalysisScript -ArgumentList $Hours -ErrorAction Stop
            }
            else {
                $Result = & $AnalysisScript -AnalysisHours $Hours
            }
            if (-not $Result) {
                Write-Host "No analysis data returned." -ForegroundColor Yellow
                continue
            }
            Write-Host "`nAnalysis Summary" -ForegroundColor Cyan
            Write-Host "----------------" -ForegroundColor DarkCyan
            Write-Host "Failed Logons               : $($Result.FailedLogons)"
            Write-Host "Audit Policy Changes        : $($Result.AuditPolicyChangeCount)"
            Write-Host "New Accounts                : $($Result.NewAccountCount)"
            Write-Host "Account Lockouts             : $($Result.AccountLockoutCount)"
            Write-Host "Group Membership Changes    : $($Result.GroupMembershipChangeCount)"
            Write-Host "Scheduled Tasks Created     : $($Result.ScheduledTaskCount)"
            Write-Host "Services Installed          : $($Result.ServiceInstallCount)"
            Write-Host "Suspicious PowerShell       : $($Result.SuspiciousPowerShellCount)"
            Write-Host "Suspicious Process Creation : $($Result.SuspiciousProcessCount)"
            Write-Host "`nFindings" -ForegroundColor Cyan
            Write-Host "--------" -ForegroundColor DarkCyan
            if (-not $Result.Findings -or $Result.Findings.Count -eq 0) {
                Write-Host "No suspicious activity matched the current detection rules." -ForegroundColor Green
                continue
            }
            $Result.Findings |
                Sort-Object @{Expression = {
                    switch ($_.Severity) {
                        'High' { 1 }
                        'Medium' { 2 }
                        'Low' { 3 }
                        default { 4 }
                    }
                }}, Time -Descending |
                Select-Object Severity,Category,Time,Source,Details |
                Format-Table -AutoSize -Wrap
        }
        catch {
            Write-Host "Failed to analyze suspicious activity." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
}