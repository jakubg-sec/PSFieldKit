function Stop-PSFieldKitService {
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

                if ($Service.State -eq 'Stopped') {
                    Write-Host "`nService '$ServiceName' is already stopped." `
                        -ForegroundColor Yellow
                    return
                }

                $Result = Invoke-CimMethod `
                    -InputObject $Service `
                    -MethodName StopService `
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

            if ($Service.State -eq 'Stopped') {
                Write-Host "`nService '$ServiceName' is already stopped." `
                    -ForegroundColor Yellow
                return
            }

            $Result = Invoke-CimMethod `
                -InputObject $Service `
                -MethodName StopService `
                -ErrorAction Stop
        }

        if ($Result.ReturnValue -eq 0) {
            Write-Host "`nService '$ServiceName' stopped successfully." `
                -ForegroundColor Green
        }
        else {
            Write-Host "`nFailed to stop service '$ServiceName'." `
                -ForegroundColor Red

            Write-Host "Return code: $($Result.ReturnValue)" `
                -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nFailed to stop service '$ServiceName' on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}