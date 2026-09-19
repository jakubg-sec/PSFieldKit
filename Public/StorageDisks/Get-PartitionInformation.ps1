function Get-PartitionInformation {
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
                $Partitions = Get-Partition `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Partitions = Get-Partition `
                -ErrorAction Stop
        }

        if ($null -eq $Partitions -or $Partitions.Count -eq 0) {
            Write-Host "`nNo partitions found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nPartition Information" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan

        $Partitions |
            Select-Object `
                DiskNumber,
                PartitionNumber,
                DriveLetter,
                Type,
                GptType,
                @{Name = 'Size(GB)'; Expression = {
                    [math]::Round($_.Size / 1GB, 2)
                }},
                @{Name = 'Offset(GB)'; Expression = {
                    [math]::Round($_.Offset / 1GB, 2)
                }},
                IsActive,
                IsBoot,
                IsSystem,
                IsHidden |
            Sort-Object DiskNumber, PartitionNumber |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve partition information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}