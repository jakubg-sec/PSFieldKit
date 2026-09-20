function Get-ArchivedEvtLogAnalysis {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsRemote -or $Context.IsMultiTarget) {
        Write-Host "`nArchived Evt Log Analysis is available only for a local target." -ForegroundColor Yellow
        return
    }

    $LogPath = Read-Host "Enter EVTX file path"

    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        Write-Host "`nEVTX log path cannot be empty." -ForegroundColor Red
        return
    }

    if (-not (Test-Path -Path $LogPath -PathType Leaf)) {
        Write-Host "`nEVTX log file was not found." -ForegroundColor Red
        return
    }

    $LogPath = (Resolve-Path -Path $LogPath).Path

    if ([System.IO.Path]::GetExtension($LogPath) -ne '.evtx') {
        Write-Host "`nThe specified file is not an EVTX file." -ForegroundColor Red
        return
    }

    try {
        Write-Host "`nArchived Evt Log Analysis" -ForegroundColor Cyan
        Write-Host "---------------------------" -ForegroundColor DarkCyan
        Write-Host "File: $LogPath" -ForegroundColor Yellow

        $Evts = @(
            Get-WinEvt `
                -Path $LogPath `
                -ErrorAction Stop
        )

        if ($Evts.Count -eq 0) {
            Write-Host "`nNo Evts were found in the specified log." -ForegroundColor Yellow
            return
        }

        $EvtCounts = @{}

        foreach ($Evt in $Evts) {
            $EvtId = [int]$Evt.Id

            if ($EvtCounts.ContainsKey($EvtId)) {
                $EvtCounts[$EvtId]++
            }
            else {
                $EvtCounts[$EvtId] = 1
            }
        }

        $SecurityRelevantIds = @(
            4624
            4625
            4672
            4688
            4698
            4719
            4720
            4728
            4732
            4740
            4756
            4771
            4776
            1102
            4103
            4104
            7045
        )

        $RelevantEvts = @(
            $Evts |
            Where-Object {
                $_.Id -in $SecurityRelevantIds
            }
        )

        $Findings = @()

        $FailedLogonsBySource = @{}

        foreach ($Evt in $RelevantEvts | Where-Object { $_.Id -eq 4625 }) {
            try {
                $Xml = [xml]$Evt.ToXml()

                $SourceIpNode = $Xml.Evt.EvtData.Data |
                    Where-Object {
                        $_.Name -eq 'IpAddress'
                    } |
                    Select-Object -First 1

                $SourceIp = if ($null -ne $SourceIpNode) {
                    [string]$SourceIpNode.'#text'
                }
                else {
                    'Unknown'
                }

                if ([string]::IsNullOrWhiteSpace($SourceIp)) {
                    $SourceIp = 'Unknown'
                }

                if ($SourceIp -in @('Unknown', '-', '127.0.0.1', '::1')) {
                    continue
                }

                if ($FailedLogonsBySource.ContainsKey($SourceIp)) {
                    $FailedLogonsBySource[$SourceIp]++
                }
                else {
                    $FailedLogonsBySource[$SourceIp] = 1
                }
            }
            catch {
                continue
            }
        }

        foreach ($SourceIp in $FailedLogonsBySource.Keys) {
            $Count = [int]$FailedLogonsBySource[$SourceIp]

            $LastEvt = $RelevantEvts |
                Where-Object {
                    $_.Id -eq 4625
                } |
                Sort-Object TimeCreated |
                Select-Object -Last 1

            if ($Count -ge 25) {
                $Findings += [PSCustomObject]@{
                    Time = if ($null -ne $LastEvt) {
                        $LastEvt.TimeCreated
                    }
                    else {
                        $null
                    }
                    Severity = 'High'
                    Category = 'Authentication'
                    EvtId = 4625
                    Finding = "High number of failed logons from $SourceIp ($Count attempts)."
                }
            }
            elseif ($Count -ge 10) {
                $Findings += [PSCustomObject]@{
                    Time = if ($null -ne $LastEvt) {
                        $LastEvt.TimeCreated
                    }
                    else {
                        $null
                    }
                    Severity = 'Medium'
                    Category = 'Authentication'
                    EvtId = 4625
                    Finding = "Repeated failed logons from $SourceIp ($Count attempts)."
                }
            }
        }

        foreach ($Evt in $RelevantEvts) {
            switch ($Evt.Id) {
                1102 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'High'
                        Category = 'Audit'
                        EvtId = 1102
                        Finding = 'Security Evt log was cleared.'
                    }
                }

                4719 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'High'
                        Category = 'Audit'
                        EvtId = 4719
                        Finding = 'System audit policy was changed.'
                    }
                }

                4720 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'Medium'
                        Category = 'Account'
                        EvtId = 4720
                        Finding = 'A new user account was created.'
                    }
                }

                4740 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'Medium'
                        Category = 'Authentication'
                        EvtId = 4740
                        Finding = 'A user account was locked out.'
                    }
                }

                4728 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'Medium'
                        Category = 'Privilege'
                        EvtId = 4728
                        Finding = 'A member was added to a security-enabled global group.'
                    }
                }

                4732 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'Medium'
                        Category = 'Privilege'
                        EvtId = 4732
                        Finding = 'A member was added to a security-enabled local group.'
                    }
                }

                4756 {
                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = 'Medium'
                        Category = 'Privilege'
                        EvtId = 4756
                        Finding = 'A member was added to a security-enabled universal group.'
                    }
                }

                4698 {
                    $Message = [string]$Evt.Message

                    $Severity = if (
                        $Message -match 'powershell' -or
                        $Message -match 'cmd\.exe' -or
                        $Message -match 'wscript' -or
                        $Message -match 'cscript' -or
                        $Message -match 'mshta' -or
                        $Message -match 'AppData' -or
                        $Message -match '\\Temp\\'
                    ) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = $Severity
                        Category = 'Persistence'
                        EvtId = 4698
                        Finding = 'A scheduled task was created.'
                    }
                }

                7045 {
                    $Message = [string]$Evt.Message

                    $Severity = if (
                        $Message -match 'powershell' -or
                        $Message -match 'cmd\.exe' -or
                        $Message -match 'wscript' -or
                        $Message -match 'cscript' -or
                        $Message -match 'mshta' -or
                        $Message -match 'rundll32' -or
                        $Message -match 'regsvr32' -or
                        $Message -match 'AppData' -or
                        $Message -match '\\Temp\\'
                    ) {
                        'High'
                    }
                    else {
                        'Medium'
                    }

                    $Findings += [PSCustomObject]@{
                        Time = $Evt.TimeCreated
                        Severity = $Severity
                        Category = 'Persistence'
                        EvtId = 7045
                        Finding = 'A new Windows service was installed.'
                    }
                }

                4104 {
                    $Message = [string]$Evt.Message

                    if (
                        $Message -match 'EncodedCommand' -or
                        $Message -match 'FromBase64String' -or
                        $Message -match 'DownloadString' -or
                        $Message -match 'Invoke-WebRequest' -or
                        $Message -match 'Invoke-Expression' -or
                        $Message -match '\bIEX\b' -or
                        $Message -match 'Reflection' -or
                        $Message -match 'Add-Type' -or
                        $Message -match 'Hidden'
                    ) {
                        $Findings += [PSCustomObject]@{
                            Time = $Evt.TimeCreated
                            Severity = 'High'
                            Category = 'PowerShell'
                            EvtId = 4104
                            Finding = 'PowerShell activity matched a suspicious command pattern.'
                        }
                    }
                }
            }
        }

        Write-Host "`nLog Summary" -ForegroundColor Cyan
        Write-Host "-----------" -ForegroundColor DarkCyan
        Write-Host "Total Evts : $($Evts.Count)"
        Write-Host "Relevant     : $($RelevantEvts.Count)"

        $FirstEvt = $Evts |
            Sort-Object TimeCreated |
            Select-Object -First 1

        $LastEvt = $Evts |
            Sort-Object TimeCreated |
            Select-Object -Last 1

        Write-Host "First Evt  : $($FirstEvt.TimeCreated)"
        Write-Host "Last Evt   : $($LastEvt.TimeCreated)"

        Write-Host "`nKey Evt Counts" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        foreach ($EvtId in $SecurityRelevantIds) {
            $Count = 0

            if ($EvtCounts.ContainsKey($EvtId)) {
                $Count = $EvtCounts[$EvtId]
            }

            if ($Count -gt 0) {
                Write-Host "$EvtId : $Count"
            }
        }

        Write-Host "`nAnalysis Results" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        if ($Findings.Count -eq 0) {
            Write-Host "No suspicious indicators were detected." -ForegroundColor Green
            Write-Host "This does not mean the system is necessarily clean." -ForegroundColor DarkGray
            return
        }

        $SeverityOrder = @{
            High = 1
            Medium = 2
            Low = 3
        }

        $Findings |
            Sort-Object `
                @{Expression = { $SeverityOrder[$_.Severity] }; Ascending = $true},
                Time |
            Format-Table `
                Time,
                Severity,
                Category,
                EvtId,
                Finding `
            -Wrap `
            -AutoSize
    }
    catch {
        Write-Host "`nFailed to analyze archived Evt log." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}