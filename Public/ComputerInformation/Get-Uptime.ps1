function Get-Uptime {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $OperatingSystem = Get-CimInstance `
                -ClassName Win32_OperatingSystem `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop
        }
        else {

            $OperatingSystem = Get-CimInstance `
                -ClassName Win32_OperatingSystem `
                -ErrorAction Stop
        }

        $Uptime = New-TimeSpan `
            -Start $OperatingSystem.LastBootUpTime `
            -End (Get-Date)

        [PSCustomObject]@{
            LastBootUpTime = $OperatingSystem.LastBootUpTime
            Days           = $Uptime.Days
            Hours          = $Uptime.Hours
            Minutes        = $Uptime.Minutes
            TotalHours     = [math]::Round($Uptime.TotalHours, 2)
        }
    }
    catch {

        Write-Host "`nFailed to retrieve uptime from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}