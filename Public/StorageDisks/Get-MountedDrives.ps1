function Get-MountedDrives {
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
                $Drives = Get-CimInstance `
                    -ClassName Win32_LogicalDisk `
                    -CimSession $Session `
                    -Filter "DriveType = 3 OR DriveType = 4" `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Drives = Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -Filter "DriveType = 3 OR DriveType = 4" `
                -ErrorAction Stop
        }

        if ($null -eq $Drives -or $Drives.Count -eq 0) {
            Write-Host "`nNo mounted drives found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nMounted Drives" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $Drives |
            Select-Object `
                DeviceID,
                VolumeName,
                FileSystem,
                DriveType,
                @{Name = 'Size(GB)'; Expression = {
                    if ($null -ne $_.Size) {
                        [math]::Round($_.Size / 1GB, 2)
                    }
                    else {
                        $null
                    }
                }},
                @{Name = 'FreeSpace(GB)'; Expression = {
                    if ($null -ne $_.FreeSpace) {
                        [math]::Round($_.FreeSpace / 1GB, 2)
                    }
                    else {
                        $null
                    }
                }},
                @{Name = 'FreeSpace(%)'; Expression = {
                    if ($_.Size -gt 0) {
                        [math]::Round(
                            ($_.FreeSpace / $_.Size) * 100,
                            2
                        )
                    }
                    else {
                        $null
                    }
                }},
                ProviderName |
            Sort-Object DeviceID |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve mounted drives from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}