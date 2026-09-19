function Get-VolumeInformation {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

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

        if ($null -eq $Volumes -or $Volumes.Count -eq 0) {
            Write-Host "`nNo volumes found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nVolume Information" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $Volumes |
            Select-Object `
                DriveLetter,
                FileSystemLabel,
                FileSystem,
                HealthStatus,
                OperationalStatus,
                @{Name = 'Size(GB)'; Expression = {
                    if ($null -ne $_.Size) {
                        [math]::Round($_.Size / 1GB, 2)
                    }
                    else {
                        $null
                    }
                }},
                @{Name = 'FreeSpace(GB)'; Expression = {
                    if ($null -ne $_.SizeRemaining) {
                        [math]::Round($_.SizeRemaining / 1GB, 2)
                    }
                    else {
                        $null
                    }
                }},
                @{Name = 'FreeSpace(%)'; Expression = {
                    if ($_.Size -gt 0) {
                        [math]::Round(
                            ($_.SizeRemaining / $_.Size) * 100,
                            2
                        )
                    }
                    else {
                        $null
                    }
                }},
                Path |
            Sort-Object DriveLetter |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve volume information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}