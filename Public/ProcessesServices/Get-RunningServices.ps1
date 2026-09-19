function Get-RunningServices {
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
                $Services = Get-CimInstance `
                    -ClassName Win32_Service `
                    -CimSession $Session `
                    -Filter "State = 'Running'" `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Services = Get-CimInstance `
                -ClassName Win32_Service `
                -Filter "State = 'Running'" `
                -ErrorAction Stop
        }

        Write-Host "`nRunning Services" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        $Services |
            Select-Object `
                Name,
                DisplayName,
                StartMode,
                StartName,
                ProcessId |
            Sort-Object DisplayName |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve running services from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}