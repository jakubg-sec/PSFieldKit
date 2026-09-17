function Get-HardwareInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            $BIOS = Get-CimInstance `
                -ClassName Win32_BIOS `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop
        }
        else {

            $ComputerSystem = Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ErrorAction Stop

            $BIOS = Get-CimInstance `
                -ClassName Win32_BIOS `
                -ErrorAction Stop
        }

        [PSCustomObject]@{
            Manufacturer     = $ComputerSystem.Manufacturer
            Model            = $ComputerSystem.Model
            SystemType       = $ComputerSystem.SystemType
            SerialNumber     = $BIOS.SerialNumber
            BIOSVendor       = $BIOS.Manufacturer
            BIOSVersion      = $BIOS.SMBIOSBIOSVersion
            BIOSReleaseDate  = $BIOS.ReleaseDate
        }
    }
    catch {

        Write-Host "`nFailed to retrieve hardware information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}