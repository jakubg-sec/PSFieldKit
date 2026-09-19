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
                ForEach-Object {
                    $_.Trim()
                } |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                } |
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

        if (-not $ZipFileName.EndsWith(
            '.zip',
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
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
            New-Item `
                -Path $DestinationPath `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }
        elseif (-not (Get-Item -LiteralPath $DestinationPath -ErrorAction Stop).PSIsContainer) {
            Write-Host "`nDestination path is not a directory." -ForegroundColor Red
            return
        }

        $RunPath = Join-Path `
            -Path $DestinationPath `
            -ChildPath $RunName

        New-Item `
            -Path $RunPath `
            -ItemType Directory `
            -Force `
            -ErrorAction Stop |
            Out-Null

        $PeriodStartUtc = $RunStartedUtc.AddDays(-$TimeRangeDays)

        $StartTimeString = $PeriodStartUtc.ToString(
            'yyyy-MM-ddTHH:mm:ss.fffZ'
        )

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

        $Results = @()

        Write-Host "`nExport configuration" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Run ID        : $RunId"
        Write-Host "Operator      : $Operator"
        Write-Host "Export Host   : $ExportHost"
        Write-Host "Logs          : $($LogNames -join ', ')"
        Write-Host "Time range    : Last $TimeRangeDays days"
        Write-Host "Timeout       : $TimeoutSeconds seconds"
        Write-Host "From UTC      : $($PeriodStartUtc.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "Destination   : $RunPath"
        Write-Host "Targets       : $($Targets.Count)"

        if ($CreateZip) {
            Write-Host "ZIP file      : $ZipFileName"
            Write-Host "Delete folder : $DeleteExportFolderAfterZip"
        }

        Write-Host

        foreach ($Target in $Targets) {
            $ComputerName = $Target.ComputerName

            Write-Host "Testing connection to $ComputerName..." `
                -ForegroundColor Yellow

            if (-not (Test-PSFieldKitTarget -ComputerName $ComputerName)) {
                Write-Host "Unable to reach $ComputerName." `
                    -ForegroundColor Red

                foreach ($LogName in $LogNames) {
                    $Results += [PSCustomObject]@{
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
                    }
                }

                continue
            }

            Write-Host "Connection successful." `
                -ForegroundColor Green

            $SafeComputerName = $ComputerName

            foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
                $SafeComputerName = $SafeComputerName.Replace(
                    $InvalidCharacter,
                    '_'
                )
            }

            $ComputerPath = Join-Path `
                -Path $RunPath `
                -ChildPath $SafeComputerName

            New-Item `
                -Path $ComputerPath `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop |
                Out-Null

            foreach ($LogName in $LogNames) {
                $LogStartTime = Get-Date
                $SafeLogName = $LogName

                foreach ($InvalidCharacter in [System.IO.Path]::GetInvalidFileNameChars()) {
                    $SafeLogName = $SafeLogName.Replace(
                        $InvalidCharacter,
                        '_'
                    )
                }

                $ExportPath = Join-Path `
                    -Path $ComputerPath `
                    -ChildPath "$SafeLogName.evtx"

                if ((Test-Path -LiteralPath $ExportPath) -and -not $Overwrite) {
                    $FileInfo = Get-Item `
                        -LiteralPath $ExportPath `
                        -ErrorAction SilentlyContinue

                    $Hash = $null

                    if ($null -ne $FileInfo) {
                        try {
                            $Hash = (
                                Get-FileHash `
                                    -LiteralPath $ExportPath `
                                    -Algorithm SHA256 `
                                    -ErrorAction Stop
                            ).Hash
                        }
                        catch {
                            $Hash = $null
                        }
                    }

                    Write-Host "Skipped: $ComputerName - $LogName" `
                        -ForegroundColor Yellow

                    $Results += [PSCustomObject]@{
                        RunId            = $RunId
                        Computer         = $ComputerName
                        Log              = $LogName
                        Status           = 'Skipped'
                        PeriodStartUtc   = $PeriodStartUtc
                        PeriodEndUtc     = $null
                        ExportedAtUtc    = $null
                        DurationSeconds  = 0
                        LogRecordCount   = $null
                        FileSizeMB       = if ($null -ne $FileInfo) {
                            [math]::Round($FileInfo.Length / 1MB, 2)
                        }
                        else {
                            $null
                        }
                        SHA256           = $Hash
                        Path             = $ExportPath
                        Operator         = $Operator
                        ExportHost       = $ExportHost
                        Error            = 'File already exists.'
                    }

                    continue
                }

                Write-Host "Exporting $LogName from $ComputerName..." `
                    -ForegroundColor Cyan

                $RemoteTempName = "PSFieldKit_$([guid]::NewGuid().ToString('N')).evtx"
                $RemoteTempPath = "C:\Windows\Temp\$RemoteTempName"
                $RemoteSharePath = "\\$ComputerName\c$\Windows\Temp\$RemoteTempName"

                try {
                    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo

                    $ProcessStartInfo.FileName = 'wevtutil.exe'
                    $ProcessStartInfo.UseShellExecute = $false
                    $ProcessStartInfo.CreateNoWindow = $true
                    $ProcessStartInfo.RedirectStandardOutput = $true
                    $ProcessStartInfo.RedirectStandardError = $true

                    if ($Target.IsRemote) {
                        $ArgumentString = @(
                            'epl'
                            "`"$LogName`""
                            "`"$RemoteTempPath`""
                            "`"/q:$Query`""
                            "/ow:$($Overwrite.ToString().ToLower())"
                            "/r:$ComputerName"
                        ) -join ' '
                    }
                    else {
                        $ArgumentString = @(
                            'epl'
                            "`"$LogName`""
                            "`"$ExportPath`""
                            "`"/q:$Query`""
                            "/ow:$($Overwrite.ToString().ToLower())"
                        ) -join ' '
                    }

                    $ProcessStartInfo.Arguments = $ArgumentString

                    $Process = New-Object System.Diagnostics.Process
                    $Process.StartInfo = $ProcessStartInfo

                    [void]$Process.Start()

                    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $LastStatusMessage = 0

                    while (-not $Process.HasExited) {
                        Start-Sleep -Seconds 5

                        $ElapsedSeconds = [int]$Stopwatch.Elapsed.TotalSeconds

                        if ($ElapsedSeconds -ge ($LastStatusMessage + 30)) {
                            Write-Host "Still exporting $LogName from $ComputerName... ($ElapsedSeconds seconds)" `
                                -ForegroundColor DarkGray

                            $LastStatusMessage = $ElapsedSeconds
                        }

                        if ($ElapsedSeconds -ge $TimeoutSeconds) {
                            try {
                                $Process.Kill()
                            }
                            catch {
                            }

                            throw "Export timeout exceeded ($TimeoutSeconds seconds)."
                        }
                    }

                    $StandardOutput = $Process.StandardOutput.ReadToEnd()
                    $StandardError = $Process.StandardError.ReadToEnd()
                    $ExitCode = $Process.ExitCode

                    $Process.Dispose()

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

                    if ($Target.IsRemote) {
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

                    $FileInfo = Get-Item `
                        -LiteralPath $ExportPath `
                        -ErrorAction Stop

                    $FileHash = Get-FileHash `
                        -LiteralPath $ExportPath `
                        -Algorithm SHA256 `
                        -ErrorAction Stop

                    $LogRecordCount = $null

                    try {
                        $LogRecordCount = @(
                            Get-WinEvent `
                                -Path $ExportPath `
                                -ErrorAction Stop
                        ).Count
                    }
                    catch {
                        $LogRecordCount = $null
                    }

                    $LogEndTime = Get-Date
                    $ExportedAtUtc = $LogEndTime.ToUniversalTime()

                    $DurationSeconds = [math]::Round(
                        ($LogEndTime - $LogStartTime).TotalSeconds,
                        2
                    )

                    $FileSizeMB = [math]::Round(
                        $FileInfo.Length / 1MB,
                        2
                    )

                    Write-Host "Export successful: $ExportPath" `
                        -ForegroundColor Green

                    Write-Host "Records: $LogRecordCount" `
                        -ForegroundColor DarkGray

                    Write-Host "File size: $FileSizeMB MB" `
                        -ForegroundColor DarkGray

                    Write-Host "SHA256: $($FileHash.Hash)" `
                        -ForegroundColor DarkGray

                    $Results += [PSCustomObject]@{
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
                        SHA256           = $FileHash.Hash
                        Path             = $ExportPath
                        Operator         = $Operator
                        ExportHost       = $ExportHost
                        Error            = $null
                    }
                }
                catch {
                    $LogEndTime = Get-Date
                    $ExportedAtUtc = $LogEndTime.ToUniversalTime()

                    $DurationSeconds = [math]::Round(
                        ($LogEndTime - $LogStartTime).TotalSeconds,
                        2
                    )

                    Write-Host "Export failed: $ComputerName - $LogName" `
                        -ForegroundColor Red

                    Write-Host $_.Exception.Message `
                        -ForegroundColor Yellow

                    $Results += [PSCustomObject]@{
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
                    if ($Target.IsRemote) {
                        if (Test-Path -LiteralPath $RemoteSharePath) {
                            Remove-Item `
                                -LiteralPath $RemoteSharePath `
                                -Force `
                                -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }

        $Results = @($Results)

        $ReportPath = Join-Path `
            -Path $RunPath `
            -ChildPath 'ExportReport.csv'

        $Results |
            Export-Csv `
                -Path $ReportPath `
                -NoTypeInformation `
                -Encoding UTF8

        $SuccessfulExports = @(
            $Results |
                Where-Object {
                    $_.Status -eq 'Success'
                }
        ).Count

        $FailedExports = @(
            $Results |
                Where-Object {
                    $_.Status -eq 'Failed'
                }
        ).Count

        $UnreachableTargets = @(
            $Results |
                Where-Object {
                    $_.Status -eq 'Unreachable'
                }
        ).Count

        $SkippedExports = @(
            $Results |
                Where-Object {
                    $_.Status -eq 'Skipped'
                }
        ).Count

        $TotalRecords = 0

        foreach ($Result in $Results) {
            if ($null -ne $Result.LogRecordCount) {
                $TotalRecords += $Result.LogRecordCount
            }
        }

        $RunCompletedUtc = (Get-Date).ToUniversalTime()

        $ManifestPath = Join-Path `
            -Path $RunPath `
            -ChildPath 'ExportManifest.json'

        $Manifest = [PSCustomObject]@{
            RunId              = $RunId
            Operator           = $Operator
            ExportHost         = $ExportHost
            StartedUtc         = $RunStartedUtc
            CompletedUtc       = $RunCompletedUtc
            DurationSeconds    = [math]::Round(
                ($RunCompletedUtc - $RunStartedUtc).TotalSeconds,
                2
            )
            DestinationPath    = $RunPath
            TargetsRequested   = $Targets.Count
            LogsRequested      = $LogNames
            TimeRangeDays      = $TimeRangeDays
            TimeoutSeconds     = $TimeoutSeconds
            PeriodStartUtc     = $PeriodStartUtc
            OverwriteExisting  = $Overwrite
            ZipRequested       = $CreateZip
            ZipFileName        = $ZipFileName
            DeleteFolderAfterZip = $DeleteExportFolderAfterZip
            TotalResults       = $Results.Count
            SuccessfulExports  = $SuccessfulExports
            FailedExports      = $FailedExports
            UnreachableTargets = $UnreachableTargets
            SkippedExports     = $SkippedExports
            TotalEventRecords  = $TotalRecords
            ReportFile         = $ReportPath
            ReportSHA256       = (
                Get-FileHash `
                    -LiteralPath $ReportPath `
                    -Algorithm SHA256 `
                    -ErrorAction Stop
            ).Hash
        }

        $Manifest |
            ConvertTo-Json -Depth 5 |
            Set-Content `
                -LiteralPath $ManifestPath `
                -Encoding UTF8 `
                -ErrorAction Stop

        Write-Host "`nExport Summary" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $Results |
            Select-Object `
                Computer,
                Log,
                Status,
                LogRecordCount,
                DurationSeconds,
                FileSizeMB,
                SHA256,
                Path,
                Error |
            Format-Table -Wrap -AutoSize

        Write-Host "Report   : $ReportPath" -ForegroundColor Yellow
        Write-Host "Manifest : $ManifestPath" -ForegroundColor Yellow

        if ($CreateZip) {
            $ZipPath = Join-Path `
                -Path $DestinationPath `
                -ChildPath $ZipFileName

            if ((Test-Path -LiteralPath $ZipPath) -and $Overwrite) {
                Remove-Item `
                    -LiteralPath $ZipPath `
                    -Force `
                    -ErrorAction Stop
            }

            if ((Test-Path -LiteralPath $ZipPath) -and -not $Overwrite) {
                Write-Host "`nZIP archive already exists:" -ForegroundColor Yellow
                Write-Host $ZipPath -ForegroundColor Yellow
            }
            else {
                Compress-Archive `
                    -Path (Join-Path $RunPath '*') `
                    -DestinationPath $ZipPath `
                    -Force `
                    -ErrorAction Stop

                Write-Host "`nZIP archive created:" -ForegroundColor Green
                Write-Host $ZipPath -ForegroundColor Yellow

                if ($DeleteExportFolderAfterZip) {
                    if (Test-Path -LiteralPath $ZipPath) {
                        Write-Host "`nRemoving temporary export folder..." `
                            -ForegroundColor Yellow

                        Remove-Item `
                            -LiteralPath $RunPath `
                            -Recurse `
                            -Force `
                            -ErrorAction Stop

                        Write-Host "Export folder removed successfully." `
                            -ForegroundColor Green

                        Write-Host "ZIP archive preserved: $ZipPath" `
                            -ForegroundColor DarkGray
                    }
                }
            }
        }
    }
    catch {
        Write-Host "`nFailed to export event logs." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}