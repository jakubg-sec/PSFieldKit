function Get-SystemInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsRemote) {

        $ComputerSystem = Get-CimInstance `
            -ClassName Win32_ComputerSystem `
            -ComputerName $Context.ComputerName

        $OperatingSystem = Get-CimInstance `
            -ClassName Win32_OperatingSystem `
            -ComputerName $Context.ComputerName

        $BIOS = Get-CimInstance `
            -ClassName Win32_BIOS `
            -ComputerName $Context.ComputerName
    }
    else {

        $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

        $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem

        $BIOS = Get-CimInstance -ClassName Win32_BIOS
    }

    $Uptime = New-TimeSpan `
        -Start $OperatingSystem.LastBootUpTime `
        -End (Get-Date)

    [PSCustomObject]@{
        ComputerName    = $ComputerSystem.ComputerName
        OperatingSystem = $OperatingSystem.Caption
        Version         = $OperatingSystem.Version
        Architecture    = $OperatingSystem.OSArchitecture
        Manufacturer    = $ComputerSystem.Manufacturer
        Model           = $ComputerSystem.Model
        SerialNumber    = $BIOS.SerialNumber
        Domain          = $ComputerSystem.Domain
        LoggedOnUser    = $ComputerSystem.UserName
        Uptime          = "{0} days, {1} hours, {2} minutes" -f `
                          $Uptime.Days,
                          $Uptime.Hours,
                          $Uptime.Minutes
        LastBoot        = $OperatingSystem.LastBootUpTime
        PowerShell      = $PSVersionTable.PSVersion.ToString()
    }
}