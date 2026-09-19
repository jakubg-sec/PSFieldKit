function Get-RunningProcesses {
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
                $Processes = Get-CimInstance `
                    -ClassName Win32_Process `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Processes = Get-CimInstance `
                -ClassName Win32_Process `
                -ErrorAction Stop
        }

        Write-Host "`nRunning Processes" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor DarkCyan

        $Processes |
            Select-Object `
                ProcessId,
                Name,
                @{Name = 'Memory(MB)'; Expression = {
                    [math]::Round($_.WorkingSetSize / 1MB, 2)
                }},
                @{Name = 'Threads'; Expression = {
                    $_.ThreadCount
                }} |
            Sort-Object ProcessId |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve running processes from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}