function Get-MemoryInformation {

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

        $TotalMemoryGB = $OperatingSystem.TotalVisibleMemorySize / 1MB
        $FreeMemoryGB  = $OperatingSystem.FreePhysicalMemory / 1MB
        $UsedMemoryGB  = $TotalMemoryGB - $FreeMemoryGB
        $UsagePercent  = ($UsedMemoryGB / $TotalMemoryGB) * 100

        [PSCustomObject]@{
            TotalMemoryGB = [math]::Round($TotalMemoryGB, 2)
            AvailableGB   = [math]::Round($FreeMemoryGB, 2)
            UsedGB        = [math]::Round($UsedMemoryGB, 2)
            UsagePercent  = [math]::Round($UsagePercent, 1)
        }
    }
    catch {

        Write-Host "`nFailed to retrieve memory information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}