function Get-DiskInformation {
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
                $Disks = Get-Disk `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Disks = Get-Disk `
                -ErrorAction Stop
        }

        if ($null -eq $Disks -or $Disks.Count -eq 0) {
            Write-Host "`nNo disks found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nDisk Information" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        $Disks |
            Select-Object `
                Number,
                FriendlyName,
                SerialNumber,
                BusType,
                OperationalStatus,
                HealthStatus,
                @{Name = 'Size(GB)'; Expression = {
                    [math]::Round($_.Size / 1GB, 2)
                }},
                PartitionStyle,
                IsBoot,
                IsSystem,
                IsOffline,
                IsReadOnly |
            Sort-Object Number |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve disk information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}