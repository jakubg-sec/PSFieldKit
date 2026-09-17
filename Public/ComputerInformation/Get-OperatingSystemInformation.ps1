function Get-OperatingSystemInformation {

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

        [PSCustomObject]@{
            OperatingSystem = $OperatingSystem.Caption
            Version         = $OperatingSystem.Version
            Build           = $OperatingSystem.BuildNumber
            Architecture    = $OperatingSystem.OSArchitecture
            InstallDate     = $OperatingSystem.InstallDate
            LastBoot        = $OperatingSystem.LastBootUpTime
            ProductType     = switch ($OperatingSystem.ProductType) {
                1 { 'Workstation' }
                2 { 'Domain Controller' }
                3 { 'Server' }
                default { 'Unknown' }
            }
            RegisteredUser  = $OperatingSystem.RegisteredUser
        }
    }
    catch {
        Write-Host "`nFailed to retrieve operating system information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}