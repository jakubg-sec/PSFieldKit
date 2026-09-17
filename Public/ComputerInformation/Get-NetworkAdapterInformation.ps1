function Get-NetworkAdapterInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $Adapters = Get-CimInstance `
                -ClassName Win32_NetworkAdapter `
                -ComputerName $Context.ComputerName `
                -Filter "PhysicalAdapter = TRUE" `
                -ErrorAction Stop

            $Configurations = Get-CimInstance `
                -ClassName Win32_NetworkAdapterConfiguration `
                -ComputerName $Context.ComputerName `
                -Filter "IPEnabled = TRUE" `
                -ErrorAction Stop
        }
        else {

            $Adapters = Get-CimInstance `
                -ClassName Win32_NetworkAdapter `
                -Filter "PhysicalAdapter = TRUE" `
                -ErrorAction Stop

            $Configurations = Get-CimInstance `
                -ClassName Win32_NetworkAdapterConfiguration `
                -Filter "IPEnabled = TRUE" `
                -ErrorAction Stop
        }

        foreach ($Adapter in $Adapters) {

            $Configuration = $Configurations |
                Where-Object { $_.Index -eq $Adapter.Index }

            $IPv4 = $null
            $IPv6 = $null

            if ($Configuration) {

                $IPv4 = @(
                    $Configuration.IPAddress |
                    Where-Object {
                        $_ -notmatch ':'
                    }
                ) -join ', '

                $IPv6 = @(
                    $Configuration.IPAddress |
                    Where-Object {
                        $_ -match ':'
                    }
                ) -join ', '
            }

            [PSCustomObject]@{
                Name        = $Adapter.NetConnectionID
                Status      = $Adapter.NetConnectionStatus
                MACAddress  = $Adapter.MACAddress
                LinkSpeed   = if ($Adapter.Speed) {
                    "{0} Gbps" -f [math]::Round(
                        $Adapter.Speed / 1GB,
                        2
                    )
                }
                else {
                    $null
                }
                IPv4Address = $IPv4
                IPv6Address = $IPv6
            }
        }
    }
    catch {

        Write-Host "`nFailed to retrieve network adapter information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}