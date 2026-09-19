function Test-PSFieldKitConnection {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {
        Write-Host "`nRemote Connectivity Test" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $Results = Test-Connection `
                        -TargetName $Target.ComputerName `
                        -Count 2 `
                        -ErrorAction Stop
                }
                else {
                    $Results = Test-Connection `
                        -ComputerName $Target.ComputerName `
                        -Count 2 `
                        -ErrorAction Stop
                }

                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $AverageResponse = (
                        $Results |
                        Measure-Object -Property Latency -Average
                    ).Average
                }
                else {
                    $AverageResponse = (
                        $Results |
                        Measure-Object -Property ResponseTime -Average
                    ).Average
                }

                $AverageResponse = [math]::Round($AverageResponse, 2)

                Write-Host "ICMP Status     : Available" -ForegroundColor Green
                Write-Host "Responses       : $($Results.Count)/2"
                Write-Host "Average Response: $AverageResponse ms"
            }
            catch {
                Write-Host "ICMP Status     : Unavailable" -ForegroundColor Yellow
                Write-Host "Error           : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to test ICMP connectivity." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}