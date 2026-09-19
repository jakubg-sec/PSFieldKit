function Get-DiskUsage {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $PathInput = Read-Host "Enter path to analyze [C:\]"

    if ([string]::IsNullOrWhiteSpace($PathInput)) {
        $PathInput = 'C:\'
    }

    $ItemCountInput = Read-Host "Enter number of results [20]"
    $ItemCount = 20

    if (-not [string]::IsNullOrWhiteSpace($ItemCountInput)) {
        if (-not [int]::TryParse($ItemCountInput, [ref]$ItemCount)) {
            Write-Host "`nInvalid number of results." -ForegroundColor Red
            return
        }

        if ($ItemCount -lt 1) {
            Write-Host "`nNumber of results must be greater than 0." -ForegroundColor Red
            return
        }
    }

    try {
        if ($Context.IsRemote) {
            if ($PathInput -notmatch '^[A-Za-z]:\\.*') {
                Write-Host "`nFor remote targets, enter a local drive path such as C:\ or C:\Data." `
                    -ForegroundColor Red
                return
            }

            $DriveLetter = $PathInput.Substring(0, 1).ToUpper()
            $RelativePath = $PathInput.Substring(2).TrimStart('\')

            $ScanPath = "\\$($Context.ComputerName)\$($DriveLetter)`$"

            if (-not [string]::IsNullOrWhiteSpace($RelativePath)) {
                $ScanPath = Join-Path `
                    -Path $ScanPath `
                    -ChildPath $RelativePath
            }
        }
        else {
            $ScanPath = $PathInput
        }

        if (-not (Test-Path -LiteralPath $ScanPath -PathType Container)) {
            Write-Host "`nPath '$PathInput' was not found or is not a directory." `
                -ForegroundColor Red
            return
        }

        Write-Host "`nScanning $ScanPath..." -ForegroundColor Yellow

        $Files = @(
            Get-ChildItem `
                -LiteralPath $ScanPath `
                -File `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue
        )

        if ($null -eq $Files -or $Files.Count -eq 0) {
            Write-Host "`nNo files found." -ForegroundColor Yellow
            return
        }

        $TotalSizeBytes = (
            $Files |
            Measure-Object -Property Length -Sum
        ).Sum

        $TotalSizeGB = [math]::Round(
            $TotalSizeBytes / 1GB,
            2
        )

        $RelativeRoot = $ScanPath.TrimEnd('\') + '\'

        $DirectoryUsage = @{}

        foreach ($File in $Files) {
            $RelativePath = $File.FullName.Substring(
                $RelativeRoot.Length
            )

            $FirstLevel = $RelativePath.Split('\')[0]

            if ($RelativePath -notmatch '\\') {
                $FirstLevel = '[Root Files]'
            }

            if (-not $DirectoryUsage.ContainsKey($FirstLevel)) {
                $DirectoryUsage[$FirstLevel] = [PSCustomObject]@{
                    Name      = $FirstLevel
                    SizeBytes = [uint64]0
                    FileCount = 0
                }
            }

            $DirectoryUsage[$FirstLevel].SizeBytes += [uint64]$File.Length
            $DirectoryUsage[$FirstLevel].FileCount++
        }

        $TopDirectories = $DirectoryUsage.Values |
            ForEach-Object {
                [PSCustomObject]@{
                    Name      = $_.Name
                    SizeGB    = [math]::Round(
                        $_.SizeBytes / 1GB,
                        2
                    )
                    SizeMB    = [math]::Round(
                        $_.SizeBytes / 1MB,
                        2
                    )
                    FileCount = $_.FileCount
                }
            } |
            Sort-Object SizeGB -Descending |
            Select-Object -First $ItemCount

        $TopFiles = $Files |
            Sort-Object Length -Descending |
            Select-Object -First $ItemCount |
            Select-Object `
                FullName,
                @{Name = 'SizeGB'; Expression = {
                    [math]::Round($_.Length / 1GB, 2)
                }},
                @{Name = 'SizeMB'; Expression = {
                    [math]::Round($_.Length / 1MB, 2)
                }},
                LastWriteTime

        Write-Host "`nDisk Usage" -ForegroundColor Cyan
        Write-Host "----------" -ForegroundColor DarkCyan

        Write-Host "Target    : $($Context.ComputerName)"
        Write-Host "Path      : $PathInput"
        Write-Host "Files     : $($Files.Count)"
        Write-Host "Total Size: $TotalSizeGB GB"

        Write-Host "`nTop Directories / Categories" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan

        $TopDirectories |
            Format-Table `
                Name,
                SizeGB,
                SizeMB,
                FileCount `
                -AutoSize

        Write-Host "`nLargest Files" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkCyan

        $TopFiles |
            Format-Table `
                FullName,
                SizeGB,
                SizeMB,
                LastWriteTime `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to analyze disk usage on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}