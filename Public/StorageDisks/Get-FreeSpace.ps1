function Get-FreeSpace {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ThresholdInput = Read-Host "Enter minimum free space percentage [20]"
    $Threshold = 20

    if (-not [string]::IsNullOrWhiteSpace($ThresholdInput)) {
        if (-not [int]::TryParse($ThresholdInput, [ref]$Threshold)) {
            Write-Host "`nInvalid free space threshold." -ForegroundColor Red
            return
        }

        if ($Threshold -lt 0 -or $Threshold -gt 100) {
            Write-Host "`nFree space threshold must be between 0 and 100." -ForegroundColor Red
            return
        }
    }

    try {
        if ($Context.IsRemote) {
            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            try {
                $Volumes = Get-Volume `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Volumes = Get-Volume `
                -ErrorAction Stop
        }

        $Results = $Volumes |
            Where-Object {
                $null -ne $_.Size -and
                $_.Size -gt 0
            } |
            Select-Object `
                DriveLetter,
                FileSystemLabel,
                FileSystem,
                @{Name = 'Size(GB)'; Expression = {
                    [math]::Round($_.Size / 1GB, 2)
                }},
                @{Name = 'FreeSpace(GB)'; Expression = {
                    [math]::Round($_.SizeRemaining / 1GB, 2)
                }},
                @{Name = 'FreeSpace(%)'; Expression = {
                    [math]::Round(
                        ($_.SizeRemaining / $_.Size) * 100,
                        2
                    )
                }},
                HealthStatus |
            Where-Object {
                $_.'FreeSpace(%)' -lt $Threshold
            } |
            Sort-Object 'FreeSpace(%)'

        Write-Host "`nFree Space" -ForegroundColor Cyan
        Write-Host "----------" -ForegroundColor DarkCyan

        Write-Host "Target    : $($Context.ComputerName)"
        Write-Host "Threshold : $Threshold%"

        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Host "`nNo volumes are below the configured threshold." `
                -ForegroundColor Green

            return
        }

        Write-Host "`nVolumes below threshold:" -ForegroundColor Yellow

        $Results |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve free space information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}