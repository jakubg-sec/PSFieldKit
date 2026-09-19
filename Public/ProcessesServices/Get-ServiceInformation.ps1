function Get-ServiceInformation {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ServiceName = Read-Host "Enter service name"

    try {
        if ($Context.IsRemote) {
            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            try {
                $Service = Get-CimInstance `
                    -ClassName Win32_Service `
                    -CimSession $Session `
                    -ErrorAction Stop |
                    Where-Object {
                        $_.Name -eq $ServiceName -or
                        $_.DisplayName -eq $ServiceName
                    }
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Service = Get-CimInstance `
                -ClassName Win32_Service `
                -ErrorAction Stop |
                Where-Object {
                    $_.Name -eq $ServiceName -or
                    $_.DisplayName -eq $ServiceName
                }
        }

        if ($null -eq $Service) {
            Write-Host "`nService '$ServiceName' was not found on $($Context.ComputerName)." `
                -ForegroundColor Red

            return
        }

        Write-Host "`nService Information" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan

        Write-Host "Target        : $($Context.ComputerName)"
        Write-Host "Name          : $($Service.Name)"
        Write-Host "Display Name  : $($Service.DisplayName)"
        Write-Host "Description   : $($Service.Description)"
        Write-Host "State         : $($Service.State)"
        Write-Host "Start Mode    : $($Service.StartMode)"
        Write-Host "Start Account : $($Service.StartName)"
        Write-Host "Process ID    : $($Service.ProcessId)"
        Write-Host "Path          : $($Service.PathName)"
    }
    catch {
        Write-Host "`nFailed to retrieve service information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}