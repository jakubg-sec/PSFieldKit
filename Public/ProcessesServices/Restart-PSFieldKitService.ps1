function Restart-PSFieldKitService {
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

                Write-Host "`nStopping service '$ServiceName'..." -ForegroundColor Yellow

                $StopResult = Invoke-CimMethod `
                    -InputObject $Service `
                    -MethodName StopService `
                    -ErrorAction Stop

                if ($StopResult.ReturnValue -ne 0) {
                    Write-Host "`nFailed to stop service '$ServiceName'." `
                        -ForegroundColor Red

                    Write-Host "Return code: $($StopResult.ReturnValue)" `
                        -ForegroundColor Yellow

                    return
                }

                do {
                    Start-Sleep -Seconds 1

                    $Service = Get-CimInstance `
                        -ClassName Win32_Service `
                        -CimSession $Session `
                        -Filter "Name = '$ServiceName'" `
                        -ErrorAction Stop
                }
                while ($Service.State -ne 'Stopped')

                Write-Host "Starting service '$ServiceName'..." -ForegroundColor Yellow

                $StartResult = Invoke-CimMethod `
                    -InputObject $Service `
                    -MethodName StartService `
                    -ErrorAction Stop

                if ($StartResult.ReturnValue -ne 0) {
                    Write-Host "`nFailed to start service '$ServiceName'." `
                        -ForegroundColor Red

                    Write-Host "Return code: $($StartResult.ReturnValue)" `
                        -ForegroundColor Yellow

                    return
                }

                do {
                    Start-Sleep -Seconds 1

                    $Service = Get-CimInstance `
                        -ClassName Win32_Service `
                        -CimSession $Session `
                        -Filter "Name = '$ServiceName'" `
                        -ErrorAction Stop
                }
                while ($Service.State -ne 'Running')
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

            Write-Host "`nStopping service '$ServiceName'..." -ForegroundColor Yellow

            $StopResult = Invoke-CimMethod `
                -InputObject $Service `
                -MethodName StopService `
                -ErrorAction Stop

            if ($StopResult.ReturnValue -ne 0) {
                Write-Host "`nFailed to stop service '$ServiceName'." `
                    -ForegroundColor Red

                Write-Host "Return code: $($StopResult.ReturnValue)" `
                    -ForegroundColor Yellow

                return
            }

            do {
                Start-Sleep -Seconds 1

                $Service = Get-CimInstance `
                    -ClassName Win32_Service `
                    -Filter "Name = '$ServiceName'" `
                    -ErrorAction Stop
            }
            while ($Service.State -ne 'Stopped')

            Write-Host "Starting service '$ServiceName'..." -ForegroundColor Yellow

            $StartResult = Invoke-CimMethod `
                -InputObject $Service `
                -MethodName StartService `
                -ErrorAction Stop

            if ($StartResult.ReturnValue -ne 0) {
                Write-Host "`nFailed to start service '$ServiceName'." `
                    -ForegroundColor Red

                Write-Host "Return code: $($StartResult.ReturnValue)" `
                    -ForegroundColor Yellow

                return
            }

            do {
                Start-Sleep -Seconds 1

                $Service = Get-CimInstance `
                    -ClassName Win32_Service `
                    -Filter "Name = '$ServiceName'" `
                    -ErrorAction Stop
            }
            while ($Service.State -ne 'Running')
        }

        Write-Host "`nService '$ServiceName' restarted successfully." `
            -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to restart service '$ServiceName' on $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}