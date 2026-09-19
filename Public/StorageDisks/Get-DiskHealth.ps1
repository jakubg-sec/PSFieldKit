function Get-DiskHealth {
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
                $Disks = Get-PhysicalDisk `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Disks = Get-PhysicalDisk `
                -ErrorAction Stop
        }

        if ($null -eq $Disks -or $Disks.Count -eq 0) {
            Write-Host "`nNo physical disks found." -ForegroundColor Yellow
            return
        }

        $HealthyCount = @(
            $Disks |
                Where-Object {
                    $_.HealthStatus -eq 'Healthy' -and
                    $_.OperationalStatus -contains 'OK'
                }
        ).Count

        $ProblematicDisks = @(
            $Disks |
                Where-Object {
                    $_.HealthStatus -ne 'Healthy' -or
                    $_.OperationalStatus -notcontains 'OK'
                }
        )

        Write-Host "`nDisk Health" -ForegroundColor Cyan
        Write-Host "-----------" -ForegroundColor DarkCyan

        Write-Host "Target         : $($Context.ComputerName)"
        Write-Host "Physical Disks : $($Disks.Count)"
        Write-Host "Healthy        : $HealthyCount"
        Write-Host "Problems       : $($ProblematicDisks.Count)"

        if ($ProblematicDisks.Count -eq 0) {
            Write-Host "`nAll physical disks report a healthy status." `
                -ForegroundColor Green

            return
        }

        Write-Host "`nProblematic Disks" -ForegroundColor Yellow
        Write-Host "-----------------" -ForegroundColor DarkCyan

        $ProblematicDisks |
            Select-Object `
                FriendlyName,
                SerialNumber,
                MediaType,
                BusType,
                HealthStatus,
                OperationalStatus,
                @{Name = 'Size(GB)'; Expression = {
                    [math]::Round($_.Size / 1GB, 2)
                }},
                CannotPool,
                IsPartial |
            Sort-Object HealthStatus, FriendlyName |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve disk health from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}