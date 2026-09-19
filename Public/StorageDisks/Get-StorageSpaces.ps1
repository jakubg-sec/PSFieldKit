function Get-StorageSpaces {
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
                $StoragePools = Get-StoragePool `
                    -CimSession $Session `
                    -ErrorAction Stop |
                    Where-Object {
                        $_.IsPrimordial -eq $false
                    }

                $VirtualDisks = Get-VirtualDisk `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $StoragePools = Get-StoragePool `
                -ErrorAction Stop |
                Where-Object {
                    $_.IsPrimordial -eq $false
                }

            $VirtualDisks = Get-VirtualDisk `
                -ErrorAction Stop
        }

        Write-Host "`nStorage Spaces" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        Write-Host "Target: $($Context.ComputerName)"

        if ($null -eq $StoragePools -or $StoragePools.Count -eq 0) {
            Write-Host "`nNo Storage Pools found." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nStorage Pools" -ForegroundColor Cyan
            Write-Host "-------------" -ForegroundColor DarkCyan

            $StoragePools |
                Select-Object `
                    FriendlyName,
                    HealthStatus,
                    OperationalStatus,
                    @{Name = 'Size(GB)'; Expression = {
                        [math]::Round($_.Size / 1GB, 2)
                    }},
                    @{Name = 'Allocated(GB)'; Expression = {
                        [math]::Round($_.AllocatedSize / 1GB, 2)
                    }} |
                Sort-Object FriendlyName |
                Format-Table -AutoSize
        }

        if ($null -eq $VirtualDisks -or $VirtualDisks.Count -eq 0) {
            Write-Host "`nNo Virtual Disks found." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nVirtual Disks" -ForegroundColor Cyan
            Write-Host "-------------" -ForegroundColor DarkCyan

            $VirtualDisks |
                Select-Object `
                    FriendlyName,
                    ResiliencySettingName,
                    HealthStatus,
                    OperationalStatus,
                    ProvisioningType,
                    @{Name = 'Size(GB)'; Expression = {
                        [math]::Round($_.Size / 1GB, 2)
                    }},
                    @{Name = 'Footprint(GB)'; Expression = {
                        [math]::Round($_.FootprintOnPool / 1GB, 2)
                    }} |
                Sort-Object FriendlyName |
                Format-Table -AutoSize
        }
    }
    catch {
        Write-Host "`nFailed to retrieve Storage Spaces information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}