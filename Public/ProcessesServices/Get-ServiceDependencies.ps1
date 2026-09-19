function Get-ServiceDependencies {
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
                    -Filter "Name = '$ServiceName'" `
                    -ErrorAction Stop

                if ($null -eq $Service) {
                    Write-Host "`nService '$ServiceName' was not found on $($Context.ComputerName)." `
                        -ForegroundColor Red
                    return
                }

                $Dependencies = Get-CimAssociatedInstance `
                    -InputObject $Service `
                    -Association Win32_DependentService `
                    -ResultClassName Win32_Service `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Service = Get-CimInstance `
                -ClassName Win32_Service `
                -Filter "Name = '$ServiceName'" `
                -ErrorAction Stop

            if ($null -eq $Service) {
                Write-Host "`nService '$ServiceName' was not found on $($Context.ComputerName)." `
                    -ForegroundColor Red
                return
            }

            $Dependencies = Get-CimAssociatedInstance `
                -InputObject $Service `
                -Association Win32_DependentService `
                -ResultClassName Win32_Service `
                -ErrorAction Stop
        }

        Write-Host "`nService Dependencies" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        Write-Host "Service : $($Service.Name)"
        Write-Host "Display : $($Service.DisplayName)"
        Write-Host

        if ($null -eq $Dependencies) {
            Write-Host "No service dependencies found." -ForegroundColor Yellow
            return
        }

        $Dependencies |
            Select-Object `
                Name,
                DisplayName,
                State,
                StartMode |
            Sort-Object DisplayName |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve service dependencies from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}