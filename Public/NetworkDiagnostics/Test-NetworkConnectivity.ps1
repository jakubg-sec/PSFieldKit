function Test-NetworkConnectivity {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|           Connectivity Tests                 |" -ForegroundColor Cyan
        Write-Host "|              PSFieldKit                      |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  Target: $($Context.ComputerName)            |"           
        Write-Host "|                                              |"
        Write-Host "|  [1] Ping                                    |"
        Write-Host "|  [2] Test TCP Port                           |"
        Write-Host "|  [3] Traceroute                              |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {

                Write-Host "`nTesting connectivity to $($Context.ComputerName)..." `
                    -ForegroundColor Yellow

                try {

                    $PingResult = Test-Connection `
                        -ComputerName $Context.ComputerName `
                        -Count 4 `
                        -ErrorAction Stop

                    $PingResult |
                        Select-Object `
                            Address,
                            IPV4Address,
                            ResponseTime |
                        Format-Table -AutoSize
                }
                catch {

                    Write-Host "`nPing failed." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Yellow
                }

                Pause
            }

            '2' {

                $Port = Read-Host "Enter TCP port"

                if ([string]::IsNullOrWhiteSpace($Port)) {
                    Write-Host "`nPort cannot be empty." -ForegroundColor Red
                    Pause
                    continue
                }

                if ($Port -notmatch '^\d+$' -or
                    [int]$Port -lt 1 -or
                    [int]$Port -gt 65535) {

                    Write-Host "`nInvalid TCP port." -ForegroundColor Red
                    Pause
                    continue
                }

                Write-Host "`nTesting TCP port $Port on $($Context.ComputerName)..." `
                    -ForegroundColor Yellow

                try {

                    $Result = Test-NetConnection `
                        -ComputerName $Context.ComputerName `
                        -Port $Port `
                        -WarningAction SilentlyContinue

                    [PSCustomObject]@{
                        ComputerName     = $Result.ComputerName
                        RemoteAddress    = $Result.RemoteAddress
                        RemotePort       = $Result.RemotePort
                        TcpTestSucceeded = $Result.TcpTestSucceeded
                    } |
                    Format-List
                }
                catch {

                    Write-Host "`nTCP test failed." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Yellow
                }

                Pause
            }

            '3' {

                Write-Host "`nTracing route to $($Context.ComputerName)..." `
                    -ForegroundColor Yellow

                try {

                    $Trace = Test-NetConnection `
                        -ComputerName $Context.ComputerName `
                        -TraceRoute `
                        -WarningAction SilentlyContinue

                    Write-Host "`nTrace Route" -ForegroundColor Cyan
                    Write-Host "-----------" -ForegroundColor DarkCyan

                    $Trace.TraceRoute | ForEach-Object {
                        Write-Host $_
                    }
                }
                catch {

                    Write-Host "`nTraceroute failed." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Yellow
                }

                Pause
            }

            '0' {
                return
            }

            default {

                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}