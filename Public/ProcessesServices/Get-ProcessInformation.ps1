function Get-ProcessInformation {
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

        $ProcessCount = $Processes.Count

        $TotalMemoryBytes = (
            $Processes |
            Measure-Object -Property WorkingSetSize -Sum
        ).Sum

        $TotalMemoryGB = [math]::Round(
            $TotalMemoryBytes / 1GB,
            2
        )

        $TotalThreads = (
            $Processes |
            Measure-Object -Property ThreadCount -Sum
        ).Sum

        $TotalHandles = (
            $Processes |
            Where-Object {
                $null -ne $_.HandleCount
            } |
            Measure-Object -Property HandleCount -Sum
        ).Sum

        Write-Host "`nProcess Information" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan

        Write-Host "Target        : $($Context.ComputerName)"
        Write-Host "Process Count : $ProcessCount"
        Write-Host "Total Memory  : $TotalMemoryGB GB"
        Write-Host "Total Threads : $TotalThreads"
        Write-Host "Total Handles : $TotalHandles"
    }
    catch {
        Write-Host "`nFailed to retrieve process information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}