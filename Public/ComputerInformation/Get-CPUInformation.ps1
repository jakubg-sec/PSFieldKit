function Get-CPUInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $Processors = Get-CimInstance `
                -ClassName Win32_Processor `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop
        }
        else {

            $Processors = Get-CimInstance `
                -ClassName Win32_Processor `
                -ErrorAction Stop
        }

        $LogicalProcessors = ($Processors |
            Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

        $PhysicalCores = ($Processors |
            Measure-Object -Property NumberOfCores -Sum).Sum

        [PSCustomObject]@{
            Name                = ($Processors.Name -join ', ')
            Manufacturer        = ($Processors.Manufacturer -join ', ')
            Architecture        = switch ($Processors[0].Architecture) {
                0 { 'x86' }
                1 { 'MIPS' }
                2 { 'Alpha' }
                3 { 'PowerPC' }
                5 { 'ARM' }
                6 { 'Itanium' }
                9 { 'x64' }
                default { 'Unknown' }
            }
            PhysicalCores       = $PhysicalCores
            LogicalProcessors   = $LogicalProcessors
            MaxClockSpeedMHz    = ($Processors.MaxClockSpeed -join ', ')
            CurrentClockSpeedMHz = ($Processors.CurrentClockSpeed -join ', ')
            SocketDesignation   = ($Processors.SocketDesignation -join ', ')
        }
    }
    catch {

        Write-Host "`nFailed to retrieve CPU information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}