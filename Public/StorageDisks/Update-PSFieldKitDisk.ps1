function Update-PSFieldKitDisk {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $DiskNumberInput = Read-Host "Enter disk number to rescan [All]"
    $DiskNumber = $null

    if (-not [string]::IsNullOrWhiteSpace($DiskNumberInput)) {
        if (-not [uint32]::TryParse($DiskNumberInput, [ref]$DiskNumber)) {
            Write-Host "`nInvalid disk number." -ForegroundColor Red
            return
        }
    }

    try {
        if ($Context.IsRemote) {
            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            try {
                if ($null -eq $DiskNumber) {
                    $Disks = Get-Disk `
                        -CimSession $Session `
                        -ErrorAction Stop

                    if ($null -eq $Disks -or $Disks.Count -eq 0) {
                        Write-Host "`nNo disks found." -ForegroundColor Yellow
                        return
                    }

                    foreach ($Disk in $Disks) {
                        Update-Disk `
                            -CimSession $Session `
                            -Number $Disk.Number `
                            -ErrorAction Stop |
                            Out-Null
                    }
                }
                else {
                    $Disk = Get-Disk `
                        -CimSession $Session `
                        -Number $DiskNumber `
                        -ErrorAction Stop

                    Update-Disk `
                        -CimSession $Session `
                        -Number $Disk.Number `
                        -ErrorAction Stop |
                        Out-Null
                }
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            if ($null -eq $DiskNumber) {
                $Disks = Get-Disk `
                    -ErrorAction Stop

                if ($null -eq $Disks -or $Disks.Count -eq 0) {
                    Write-Host "`nNo disks found." -ForegroundColor Yellow
                    return
                }

                foreach ($Disk in $Disks) {
                    Update-Disk `
                        -Number $Disk.Number `
                        -ErrorAction Stop |
                        Out-Null
                }
            }
            else {
                Get-Disk `
                    -Number $DiskNumber `
                    -ErrorAction Stop |
                    Update-Disk `
                        -ErrorAction Stop |
                    Out-Null
            }
        }

        Write-Host "`nDisk rescan completed successfully." -ForegroundColor Green
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        if ($null -eq $DiskNumber) {
            Write-Host "Scope : All disks"
        }
        else {
            Write-Host "Scope : Disk $DiskNumber"
        }
    }
    catch {
        Write-Host "`nFailed to rescan disks on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}