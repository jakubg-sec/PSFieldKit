function Export-EventLogs {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $LogInput = Read-Host "Enter logs to export [System,Application,Security]"

    if ([string]::IsNullOrWhiteSpace($LogInput)) {
        $LogNames = @(
            'System'
            'Application'
            'Security'
        )
    }
    else {
        $LogNames = @(
            $LogInput -split ',' |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
    }

    if ($null -eq $LogNames -or $LogNames.Count -eq 0) {
        Write-Host "`nNo event logs were specified." -ForegroundColor Red
        return
    }

    $DestinationPath = Read-Host "Destination path [C:\PSFieldKit\EventLogs]"
    if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
        $DestinationPath = 'C:\PSFieldKit\EventLogs'
    }

    $TimeRangeInput = Read-Host "Time range [30 days]"
    $TimeRangeDays = 0
    if ([string]::IsNullOrWhiteSpace($TimeRangeInput)) {
        $TimeRangeDays = 30
    }
    elseif (-not [int]::TryParse($TimeRangeInput, [ref]$TimeRangeDays)) {
        Write-Host "`nInvalid time range." -ForegroundColor Red
        return
    }
    elseif ($TimeRangeDays -lt 1) {
        Write-Host "`nTime range must be greater than 0." -ForegroundColor Red
        return
    }

    $TimeoutInput = Read-Host "Export timeout per log [600 seconds]"
    $TimeoutSeconds = 0
    if ([string]::IsNullOrWhiteSpace($TimeoutInput)) {
        $TimeoutSeconds = 600
    }
    elseif (-not [int]::TryParse($TimeoutInput, [ref]$TimeoutSeconds)) {
        Write-Host "`nInvalid timeout." -ForegroundColor Red
        return
    }
    elseif ($TimeoutSeconds -lt 1) {
        Write-Host "`nTimeout must be greater than 0." -ForegroundColor Red
        return
    }

    $ConcurrencyInput = Read-Host "Maximum concurrent exports [4]"
    $MaxConcurrency = 0
    if ([string]::IsNullOrWhiteSpace($ConcurrencyInput)) {
        $MaxConcurrency = 4
    }
    elseif (-not [int]::TryParse($ConcurrencyInput, [ref]$MaxConcurrency)) {
        Write-Host "`nInvalid concurrency value." -ForegroundColor Red
        return
    }
    elseif ($MaxConcurrency -lt 1) {
        Write-Host "`nMaximum concurrent exports must be greater than 0." -ForegroundColor Red
        return
    }
    elseif ($MaxConcurrency -gt 32) {
        Write-Host "`nMaximum concurrent exports cannot exceed 32." -ForegroundColor Red
        return
    }

    $OverwriteInput = Read-Host "Overwrite existing files [N]"
    if ([string]::IsNullOrWhiteSpace($OverwriteInput)) {
        $Overwrite = $false
    }
    elseif ($OverwriteInput -match '^(Y|YES)$') {
        $Overwrite = $true
    }
    elseif ($OverwriteInput -match '^(N|NO)$') {
        $Overwrite = $false
    }
    else {
        Write-Host "`nInvalid overwrite option. Using default: No." -ForegroundColor Yellow
        $Overwrite = $false
    }

    $CountInput = Read-Host "Calculate event count in exported files [Y]"
    if ([string]::IsNullOrWhiteSpace($CountInput)) {
        $CalculateEventCount = $true
    }
    elseif ($CountInput -match '^(Y|YES)$') {
        $CalculateEventCount = $true
    }
    elseif ($CountInput -match '^(N|NO)$') {
        $CalculateEventCount = $false
    }
    else {
        Write-Host "`nInvalid event count option. Using default: Yes." -ForegroundColor Yellow
        $CalculateEventCount = $true
    }

    $HashInput = Read-Host "Calculate SHA256 [Y]"
    if ([string]::IsNullOrWhiteSpace($HashInput)) {
        $CalculateSHA256 = $true
    }
    elseif ($HashInput -match '^(Y|YES)$') {
        $CalculateSHA256 = $true
    }
    elseif ($HashInput -match '^(N|NO)$') {
        $CalculateSHA256 = $false
    }
    else {
        Write-Host "`nInvalid SHA256 option. Using default: Yes." -ForegroundColor Yellow
        $CalculateSHA256 = $true
    }

    $ZipInput = Read-Host "Create ZIP archive after export [N]"
    if ([string]::IsNullOrWhiteSpace($ZipInput)) {
        $CreateZip = $false
    }
    elseif ($ZipInput -match '^(Y|YES)$') {
        $CreateZip = $true
    }
    elseif ($ZipInput -match '^(N|NO)$') {
        $CreateZip = $false
    }
    else {
        Write-Host "`nInvalid ZIP option. Using default: No." -ForegroundColor Yellow
        $CreateZip = $false
    }

    $RunName = Get-Date -Format 'yyyyMMdd_HHmmss'
    $RunId = [guid]::NewGuid().ToString()
    $DefaultZipName = "PSFieldKit_EventLogs_$RunName.zip"
    $ZipFileName = $null
    $DeleteExportFolderAfterZip = $false

    if ($CreateZip) {
        $ZipFileName = Read-Host "ZIP file name [$DefaultZipName]"
        if ([string]::IsNullOrWhiteSpace($ZipFileName)) {
            $ZipFileName = $DefaultZipName
        }
        if (-not $ZipFileName.EndsWith('.zip', [System.StringComparison]::OrdinalIgnoreCase)) {
            $ZipFileName = "$ZipFileName.zip"
        }

        $DeleteFolderInput = Read-Host "Delete export folder after ZIP [N]"
        if ([string]::IsNullOrWhiteSpace($DeleteFolderInput)) {
            $DeleteExportFolderAfterZip = $false
        }
        elseif ($DeleteFolderInput -match '^(Y|YES)$') {
            $DeleteExportFolderAfterZip = $true
        }
        elseif ($DeleteFolderInput -match '^(N|NO)$') {
            $DeleteExportFolderAfterZip = $false
        }
        else {
            Write-Host "`nInvalid delete option. Using default: No." -ForegroundColor Yellow
            $DeleteExportFolderAfterZip = $false
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:USERDOMAIN)) {
        $Operator = $env:USERNAME
    }
    else {
        $Operator = "$($env:USERDOMAIN)\$($env:USERNAME)"
    }

    $ExportHost = $env:COMPUTERNAME

    try {
        $RunStartedUtc = (Get-Date).ToUniversalTime()

        if (-not (Test-Path -LiteralPath $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        elseif (-not (Get-Item -LiteralPath $DestinationPath -ErrorAction Stop).PSIsContainer) {
            Write-Host "`nDestination path is not a directory." -ForegroundColor Red
            return
        }

        $RunPath = Join-Path -Path $DestinationPath -ChildPath $RunName
        New-Item -Path $RunPath -ItemType Directory -Force -ErrorAction Stop | Out-Null

        $PeriodStartUtc = $RunStartedUtc.AddDays(-$TimeRangeDays)
        $StartTimeString = $PeriodStartUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        $Query = "*[System[TimeCreated[@SystemTime >= '$StartTimeString']]]"

        if ($Context.IsMultiTarget) {
            $Targets = @($Context.Targets)
        }
        else {
            $Targets = @(
                [PSCustomObject]@{
                    ComputerName = $Context.ComputerName
                    IsRemote     = $Context.IsRemote
                }
            )
        }

        $Results = New-Object System.Collections.ArrayList
        $ReachableTargets = New-Object System.Collections.ArrayList

        Write-Host "`nExport configuration" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Run ID                 : $RunId"
        Write-Host "Operator               : $Operator"
        Write-Host "Export Host            : $ExportHost"
        Write-Host "Logs                   : $($LogNames -join ', ')"
        Write-Host "Time range             : Last $TimeRangeDays days"
        Write-Host "Timeout                : $TimeoutSeconds seconds"
        Write-Host "Max concurrency        : $MaxConcurrency"
        Write-Host "Count records          : $CalculateEventCount"
        Write-Host "SHA256                 : $CalculateSHA256"
        Write-Host "From UTC               : $($PeriodStartUtc.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "Destination            : $RunPath"
        Write-Host "Targets                : $($Targets.Count)"
        if ($CreateZip) {
            Write-Host "ZIP file               : $ZipFileName"
            Write-Host "Delete folder          : $DeleteExportFolderAfterZip"
        }
        Write-Host

        foreach ($Target in $Targets) {
            $ComputerName = $Target.ComputerName
            Write-Host "Testing connection to $ComputerName..." -ForegroundColor Yellow

            if (-not (Test-PSFieldKitTarget -ComputerName $ComputerName)) {
                Write-Host "Unable to reach $ComputerName." -ForegroundColor Red

                foreach ($LogName in $LogNames) {
                    [void]$Results.Add([PSCustomObject]@{
                        RunId            = $RunId
                        Computer         = $ComputerName
                        Log              = $LogName
                        Status           = 'Unreachable'
                        PeriodStartUtc   = $PeriodStartUtc
                        PeriodEndUtc     = $null
                        ExportedAtUtc    = $null
                        DurationSeconds  = $null
                        LogRecordCount   = $null
                        FileSizeMB       = $null
                        SHA256           = $null
                        Path             = $null
                        Operator         = $Operator
                        ExportHost       = $ExportHost
                        Error            = 'Target did not respond.'
                    })
                }
                continue
            }

            Write-Host "Connection successful." -ForegroundColor Green
            [void]$ReachableTargets.Add($Target)
        }

        $Jobs = New-Object System.Collections.ArrayList

        foreach ($Target in $ReachableTargets) {
            $ComputerName = $Target.ComputerName
            $SafeComputerName = $ComputerName

            foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
                $SafeComputerName = $SafeComputerName.Replace($InvalidCharacter, '_')
            }

            $ComputerPath = Join-Path -Path $RunPath -ChildPath $SafeComputerName
            New-Item -Path $ComputerPath -ItemType Directory -Force -ErrorAction Stop | Out-Null

            foreach ($LogName in $LogNames) {
                $SafeLogName = $LogName
                foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
                    $SafeLogName = $SafeLogName.Replace($InvalidCharacter, '_')
                }

                $ExportPath = Join-Path -Path $ComputerPath -ChildPath "$SafeLogName.evtx"

                if ((Test-Path -LiteralPath $ExportPath) -and -not $Overwrite) {
                    $FileInfo = Get-Item -LiteralPath $ExportPath -ErrorAction SilentlyContinue
                    $Hash = $null

                    if ($null -ne $FileInfo -and $CalculateSHA256) {
                        try {
                            $Hash = (Get-FileHash -LiteralPath $ExportPath -Algorithm SHA256 -ErrorAction Stop).Hash
                        }
                        catch {
                            $Hash = $null
                        }
                    }

                    Write-Host "Skipped: $ComputerName - $LogName" -ForegroundColor Yellow

                    [void]$Results.Add([PSCustomObject]@{
                        RunId            = $RunId
                        Computer         = $ComputerName
                        Log              = $LogName
                        Status           = 'Skipped'
                        PeriodStartUtc   = $PeriodStartUtc
                        PeriodEndUtc     = $null
                        ExportedAtUtc    = $null
                        DurationSeconds  = 0
                        LogRecordCount   = $null
                        FileSizeMB       = if ($null -ne $FileInfo) { [math]::Round($FileInfo.Length / 1MB, 2) } else { $null }
                        SHA256           = $Hash
                        Path             = $ExportPath
                        Operator         = $Operator
                        ExportHost       = $ExportHost
                        Error            = 'File already exists.'
                    })
                    continue
                }

                $RemoteTempName = "PSFieldKit_$([guid]::NewGuid().ToString('N')).evtx"
                [void]$Jobs.Add([PSCustomObject]@{
                    ComputerName    = $ComputerName
                    LogName         = $LogName
                    IsRemote        = [bool]$Target.IsRemote
                    ExportPath      = $ExportPath
                    RemoteTempPath  = "C:\Windows\Temp\$RemoteTempName"
                    RemoteSharePath = "\\$ComputerName\c$\Windows\Temp\$RemoteTempName"
                })
            }
        }

        $WorkerScript = {
            param(
                [string]$ComputerName,
                [string]$LogName,
                [bool]$TargetIsRemote,
                [bool]$Overwrite,
                [string]$Query,
                [int]$TimeoutSeconds,
                [bool]$CalculateEventCount,
                [bool]$CalculateSHA256,
                [string]$ExportPath,
                [string]$RemoteTempPath,
                [string]$RemoteSharePath,
                [datetime]$PeriodStartUtc,
                [string]$RunId,
                [string]$Operator,
                [string]$ExportHost
            )

            $LogStartTime = Get-Date
            $Process = $null

            try {
                $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
                $ProcessStartInfo.FileName = 'wevtutil.exe'
                $ProcessStartInfo.UseShellExecute = $false
                $ProcessStartInfo.CreateNoWindow = $true
                $ProcessStartInfo.RedirectStandardOutput = $true
                $ProcessStartInfo.RedirectStandardError = $true

                if ($TargetIsRemote) {
                    $ProcessStartInfo.Arguments = @(
                        'epl'
                        "`"$LogName`""
                        "`"$RemoteTempPath`""
                        "`"/q:$Query`""
                        "/ow:$($Overwrite.ToString().ToLower())"
                        "/r:$ComputerName"
                    ) -join ' '
                }
                else {
                    $ProcessStartInfo.Arguments = @(
                        'epl'
                        "`"$LogName`""
                        "`"$ExportPath`""
                        "`"/q:$Query`""
                        "/ow:$($Overwrite.ToString().ToLower())"
                    ) -join ' '
                }

                $Process = New-Object System.Diagnostics.Process
                $Process.StartInfo = $ProcessStartInfo
                [void]$Process.Start()

                # Start reading stdout/stderr immediately. This avoids a possible
                # child-process pipe deadlock while we wait for wevtutil.
                $StdOutTask = $Process.StandardOutput.ReadToEndAsync()
                $StdErrTask = $Process.StandardError.ReadToEndAsync()
                $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

                while (-not $Process.HasExited) {
                    if ($Stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                        try { $Process.Kill() } catch { }
                        throw "Export timeout exceeded ($TimeoutSeconds seconds)."
                    }
                    Start-Sleep -Milliseconds 250
                }

                $StandardOutput = $StdOutTask.Result
                $StandardError = $StdErrTask.Result
                $ExitCode = $Process.ExitCode

                if ($ExitCode -ne 0) {
                    $ErrorMessage = if (-not [string]::IsNullOrWhiteSpace($StandardError)) {
                        $StandardError.Trim()
                    }
                    elseif (-not [string]::IsNullOrWhiteSpace($StandardOutput)) {
                        $StandardOutput.Trim()
                    }
                    else {
                        "wevtutil exited with code $ExitCode."
                    }
                    throw $ErrorMessage
                }

                if ($TargetIsRemote) {
                    if (-not (Test-Path -LiteralPath $RemoteSharePath)) {
                        throw "Remote export file was not created."
                    }

                    Copy-Item `
                        -LiteralPath $RemoteSharePath `
                        -Destination $ExportPath `
                        -Force:$Overwrite `
                        -ErrorAction Stop
                }

                if (-not (Test-Path -LiteralPath $ExportPath)) {
                    throw "Export file was not created."
                }

                $FileInfo = Get-Item -LiteralPath $ExportPath -ErrorAction Stop
                $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
                $FileHash = $null
                $LogRecordCount = $null

                if ($CalculateSHA256) {
                    $FileHash = Get-FileHash `
                        -LiteralPath $ExportPath `
                        -Algorithm SHA256 `
                        -ErrorAction Stop
                }

                # Much cheaper than Get-WinEvent -Path ... | Count.
                # gli reads EVTX metadata and returns numberOfLogRecords.
                if ($CalculateEventCount) {
                    $InfoStartInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $InfoStartInfo.FileName = 'wevtutil.exe'
                    $InfoStartInfo.UseShellExecute = $false
                    $InfoStartInfo.CreateNoWindow = $true
                    $InfoStartInfo.RedirectStandardOutput = $true
                    $InfoStartInfo.RedirectStandardError = $true
                    $InfoStartInfo.Arguments = @(
                        'gli'
                        "`"$ExportPath`""
                        '/lf:true'
                    ) -join ' '

                    $InfoProcess = New-Object System.Diagnostics.Process
                    $InfoProcess.StartInfo = $InfoStartInfo
                    [void]$InfoProcess.Start()
                    $InfoStdOutTask = $InfoProcess.StandardOutput.ReadToEndAsync()
                    $InfoStdErrTask = $InfoProcess.StandardError.ReadToEndAsync()

                    if (-not $InfoProcess.WaitForExit([math]::Min(($TimeoutSeconds * 1000), 300000))) {
                        try { $InfoProcess.Kill() } catch { }
                        throw 'Unable to obtain exported EVTX metadata within the metadata timeout.'
                    }

                    $InfoOutput = $InfoStdOutTask.Result
                    $InfoError = $InfoStdErrTask.Result
                    $InfoExitCode = $InfoProcess.ExitCode
                    $InfoProcess.Dispose()

                    if ($InfoExitCode -eq 0) {
                        $RecordMatch = [regex]::Match(
                            $InfoOutput,
                            '(?im)^\s*numberOfLogRecords\s*:\s*(\d+)\s*$'
                        )
                        if ($RecordMatch.Success) {
                            $LogRecordCount = [int64]$RecordMatch.Groups[1].Value
                        }
                    }
                    elseif (-not [string]::IsNullOrWhiteSpace($InfoError)) {
                        $LogRecordCount = $null
                    }
                }

                $LogEndTime = Get-Date
                $ExportedAtUtc = $LogEndTime.ToUniversalTime()
                $DurationSeconds = [math]::Round(($LogEndTime - $LogStartTime).TotalSeconds, 2)

                [PSCustomObject]@{
                    RunId            = $RunId
                    Computer         = $ComputerName
                    Log              = $LogName
                    Status           = 'Success'
                    PeriodStartUtc   = $PeriodStartUtc
                    PeriodEndUtc     = $ExportedAtUtc
                    ExportedAtUtc    = $ExportedAtUtc
                    DurationSeconds  = $DurationSeconds
                    LogRecordCount   = $LogRecordCount
                    FileSizeMB       = $FileSizeMB
                    SHA256           = if ($null -ne $FileHash) { $FileHash.Hash } else { $null }
                    Path             = $ExportPath
                    Operator         = $Operator
                    ExportHost       = $ExportHost
                    Error            = $null
                }
            }
            catch {
                $LogEndTime = Get-Date
                $ExportedAtUtc = $LogEndTime.ToUniversalTime()
                $DurationSeconds = [math]::Round(($LogEndTime - $LogStartTime).TotalSeconds, 2)

                [PSCustomObject]@{
                    RunId            = $RunId
                    Computer         = $ComputerName
                    Log              = $LogName
                    Status           = 'Failed'
                    PeriodStartUtc   = $PeriodStartUtc
                    PeriodEndUtc     = $null
                    ExportedAtUtc    = $ExportedAtUtc
                    DurationSeconds  = $DurationSeconds
                    LogRecordCount   = $null
                    FileSizeMB       = $null
                    SHA256           = $null
                    Path             = $null
                    Operator         = $Operator
                    ExportHost       = $ExportHost
                    Error            = $_.Exception.Message
                }
            }
            finally {
                if ($null -ne $Process) {
                    try { $Process.Dispose() } catch { }
                }

                if ($TargetIsRemote -and (Test-Path -LiteralPath $RemoteSharePath)) {
                    Remove-Item -LiteralPath $RemoteSharePath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        $RunspacePool = $null
        $AsyncJobs = New-Object System.Collections.ArrayList
        $NextJobIndex = 0
        $CompletedCount = 0
        $TotalJobs = $Jobs.Count
        $LastProgressMessage = Get-Date

        try {
            if ($TotalJobs -gt 0) {
                $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
                    1,
                    $MaxConcurrency
                )
                $RunspacePool.Open()

                Write-Host "`nStarting optimized parallel event log exports..." -ForegroundColor Cyan
                Write-Host "Queued jobs          : $TotalJobs"
                Write-Host "Max parallel jobs    : $MaxConcurrency"
                Write-Host

                while ($CompletedCount -lt $TotalJobs) {
                    while ($AsyncJobs.Count -lt $MaxConcurrency -and $NextJobIndex -lt $TotalJobs) {
                        $Job = $Jobs[$NextJobIndex]
                        $NextJobIndex++

                        $PowerShell = [powershell]::Create()
                        $PowerShell.RunspacePool = $RunspacePool

                        [void]$PowerShell.AddScript($WorkerScript)
                        [void]$PowerShell.AddArgument($Job.ComputerName)
                        [void]$PowerShell.AddArgument($Job.LogName)
                        [void]$PowerShell.AddArgument($Job.IsRemote)
                        [void]$PowerShell.AddArgument($Overwrite)
                        [void]$PowerShell.AddArgument($Query)
                        [void]$PowerShell.AddArgument($TimeoutSeconds)
                        [void]$PowerShell.AddArgument($CalculateEventCount)
                        [void]$PowerShell.AddArgument($CalculateSHA256)
                        [void]$PowerShell.AddArgument($Job.ExportPath)
                        [void]$PowerShell.AddArgument($Job.RemoteTempPath)
                        [void]$PowerShell.AddArgument($Job.RemoteSharePath)
                        [void]$PowerShell.AddArgument($PeriodStartUtc)
                        [void]$PowerShell.AddArgument($RunId)
                        [void]$PowerShell.AddArgument($Operator)
                        [void]$PowerShell.AddArgument($ExportHost)

                        $AsyncHandle = $PowerShell.BeginInvoke()

                        [void]$AsyncJobs.Add([PSCustomObject]@{
                            ComputerName = $Job.ComputerName
                            LogName      = $Job.LogName
                            PowerShell   = $PowerShell
                            Handle       = $AsyncHandle
                        })
                    }

                    for ($Index = $AsyncJobs.Count - 1; $Index -ge 0; $Index--) {
                        $AsyncJob = $AsyncJobs[$Index]
                        if (-not $AsyncJob.Handle.IsCompleted) {
                            continue
                        }

                        try {
                            $Output = @($AsyncJob.PowerShell.EndInvoke($AsyncJob.Handle))

                            if ($Output.Count -gt 0 -and $null -ne $Output[0]) {
                                $Result = $Output[0]
                                [void]$Results.Add($Result)
                                $CompletedCount++

                                if ($Result.Status -eq 'Success') {
                                    Write-Host "[$CompletedCount/$TotalJobs] SUCCESS  $($Result.Computer) - $($Result.Log)  $($Result.DurationSeconds)s" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "[$CompletedCount/$TotalJobs] FAILED   $($Result.Computer) - $($Result.Log)" -ForegroundColor Red
                                    Write-Host "    $($Result.Error)" -ForegroundColor Yellow
                                }
                            }
                            else {
                                $CompletedCount++
                                [void]$Results.Add([PSCustomObject]@{
                                    RunId            = $RunId
                                    Computer         = $AsyncJob.ComputerName
                                    Log              = $AsyncJob.LogName
                                    Status           = 'Failed'
                                    PeriodStartUtc   = $PeriodStartUtc
                                    PeriodEndUtc     = $null
                                    ExportedAtUtc    = (Get-Date).ToUniversalTime()
                                    DurationSeconds  = $null
                                    LogRecordCount   = $null
                                    FileSizeMB       = $null
                                    SHA256           = $null
                                    Path             = $null
                                    Operator         = $Operator
                                    ExportHost       = $ExportHost
                                    Error            = 'Runspace returned no result.'
                                })

                                Write-Host "[$CompletedCount/$TotalJobs] FAILED   $($AsyncJob.ComputerName) - $($AsyncJob.LogName)" -ForegroundColor Red
                            }
                        }
                        catch {
                            $CompletedCount++
                            [void]$Results.Add([PSCustomObject]@{
                                RunId            = $RunId
                                Computer         = $AsyncJob.ComputerName
                                Log              = $AsyncJob.LogName
                                Status           = 'Failed'
                                PeriodStartUtc   = $PeriodStartUtc
                                PeriodEndUtc     = $null
                                ExportedAtUtc    = (Get-Date).ToUniversalTime()
                                DurationSeconds  = $null
                                LogRecordCount   = $null
                                FileSizeMB       = $null
                                SHA256           = $null
                                Path             = $null
                                Operator         = $Operator
                                ExportHost       = $ExportHost
                                Error            = "Runspace error: $($_.Exception.Message)"
                            })

                            Write-Host "[$CompletedCount/$TotalJobs] FAILED   $($AsyncJob.ComputerName) - $($AsyncJob.LogName)" -ForegroundColor Red
                            Write-Host "    Runspace error: $($_.Exception.Message)" -ForegroundColor Yellow
                        }
                        finally {
                            $AsyncJob.PowerShell.Dispose()
                            $AsyncJobs.RemoveAt($Index)
                        }
                    }

                    $Now = Get-Date
                    if (($Now - $LastProgressMessage).TotalSeconds -ge 30) {
                        Write-Host "Progress: $CompletedCount/$TotalJobs completed | Active: $($AsyncJobs.Count) | Queued: $($TotalJobs - $NextJobIndex)" -ForegroundColor DarkGray
                        $LastProgressMessage = $Now
                    }

                    if ($AsyncJobs.Count -gt 0) {
                        Start-Sleep -Milliseconds 250
                    }
                }
            }
            else {
                Write-Host "`nNo export jobs were created." -ForegroundColor Yellow
            }
        }
        finally {
            if ($null -ne $RunspacePool) {
                try { $RunspacePool.Close() } catch { }
                try { $RunspacePool.Dispose() } catch { }
            }
        }

        $Results = @($Results)
        $ReportPath = Join-Path -Path $RunPath -ChildPath 'ExportReport.csv'

        $Results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

        $SuccessfulExports = @($Results | Where-Object { $_.Status -eq 'Success' }).Count
        $FailedExports = @($Results | Where-Object { $_.Status -eq 'Failed' }).Count
        $UnreachableTargets = @($Results | Where-Object { $_.Status -eq 'Unreachable' }).Count
        $SkippedExports = @($Results | Where-Object { $_.Status -eq 'Skipped' }).Count

        $TotalRecords = 0
        foreach ($Result in $Results) {
            if ($null -ne $Result.LogRecordCount) {
                $TotalRecords += $Result.LogRecordCount
            }
        }

        $RunCompletedUtc = (Get-Date).ToUniversalTime()
        $ManifestPath = Join-Path -Path $RunPath -ChildPath 'ExportManifest.json'

        $Manifest = [PSCustomObject]@{
            RunId                 = $RunId
            Operator              = $Operator
            ExportHost            = $ExportHost
            StartedUtc            = $RunStartedUtc
            CompletedUtc          = $RunCompletedUtc
            DurationSeconds       = [math]::Round(($RunCompletedUtc - $RunStartedUtc).TotalSeconds, 2)
            DestinationPath       = $RunPath
            TargetsRequested      = $Targets.Count
            LogsRequested         = $LogNames
            TimeRangeDays         = $TimeRangeDays
            TimeoutSeconds        = $TimeoutSeconds
            MaxConcurrentExports  = $MaxConcurrency
            CalculateEventCount   = $CalculateEventCount
            CalculateSHA256       = $CalculateSHA256
            PeriodStartUtc        = $PeriodStartUtc
            OverwriteExisting     = $Overwrite
            ZipRequested          = $CreateZip
            ZipFileName           = $ZipFileName
            DeleteFolderAfterZip  = $DeleteExportFolderAfterZip
            TotalResults          = $Results.Count
            SuccessfulExports     = $SuccessfulExports
            FailedExports         = $FailedExports
            UnreachableTargets    = $UnreachableTargets
            SkippedExports        = $SkippedExports
            TotalEventRecords     = $TotalRecords
            ReportFile            = $ReportPath
            ReportSHA256          = (Get-FileHash -LiteralPath $ReportPath -Algorithm SHA256 -ErrorAction Stop).Hash
        }

        $Manifest |
            ConvertTo-Json -Depth 5 |
            Set-Content -LiteralPath $ManifestPath -Encoding UTF8 -ErrorAction Stop

        Write-Host "`nExport Summary" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $Results |
            Select-Object Computer, Log, Status, LogRecordCount, DurationSeconds, FileSizeMB, SHA256, Path, Error |
            Format-Table -Wrap -AutoSize

        Write-Host "Report        : $ReportPath" -ForegroundColor Yellow
        Write-Host "Manifest      : $ManifestPath" -ForegroundColor Yellow
        Write-Host "Success       : $SuccessfulExports" -ForegroundColor Green
        Write-Host "Failed        : $FailedExports" -ForegroundColor Red
        Write-Host "Skipped       : $SkippedExports" -ForegroundColor Yellow
        Write-Host "Unreachable   : $UnreachableTargets" -ForegroundColor Yellow

        if ($CreateZip) {
            $ZipPath = Join-Path -Path $DestinationPath -ChildPath $ZipFileName

            if ((Test-Path -LiteralPath $ZipPath) -and $Overwrite) {
                Remove-Item -LiteralPath $ZipPath -Force -ErrorAction Stop
            }

            if ((Test-Path -LiteralPath $ZipPath) -and -not $Overwrite) {
                Write-Host "`nZIP archive already exists:" -ForegroundColor Yellow
                Write-Host $ZipPath -ForegroundColor Yellow
            }
            else {
                Compress-Archive -Path (Join-Path $RunPath '*') -DestinationPath $ZipPath -Force -ErrorAction Stop

                Write-Host "`nZIP archive created:" -ForegroundColor Green
                Write-Host $ZipPath -ForegroundColor Yellow

                if ($DeleteExportFolderAfterZip -and (Test-Path -LiteralPath $ZipPath)) {
                    Write-Host "`nRemoving temporary export folder..." -ForegroundColor Yellow
                    Remove-Item -LiteralPath $RunPath -Recurse -Force -ErrorAction Stop
                    Write-Host "Export folder removed successfully." -ForegroundColor Green
                    Write-Host "ZIP archive preserved: $ZipPath" -ForegroundColor DarkGray
                }
            }
        }
    }
    catch {
        Write-Host "`nFailed to export event logs." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}
