function Get-NetworkAdapters {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $Adapters = Get-CimInstance `
                -ClassName Win32_NetworkAdapter `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop
        }
        else {

            $Adapters = Get-CimInstance `
                -ClassName Win32_NetworkAdapter `
                -ErrorAction Stop
        }

        $AdapterInfo = foreach ($Adapter in $Adapters) {

            [PSCustomObject]@{
                Name            = $Adapter.NetConnectionID
                Description     = $Adapter.Name
                Status          = switch ($Adapter.NetConnectionStatus) {
                    0 { 'Disconnected' }
                    1 { 'Connecting' }
                    2 { 'Connected' }
                    3 { 'Disconnecting' }
                    4 { 'Hardware Not Present' }
                    5 { 'Hardware Disabled' }
                    6 { 'Hardware Malfunction' }
                    7 { 'Media Disconnected' }
                    8 { 'Authenticating' }
                    9 { 'Authentication Succeeded' }
                    10 { 'Authentication Failed' }
                    11 { 'Invalid Address' }
                    12 { 'Credentials Required' }
                    default { 'Unknown' }
                }
                MACAddress      = $Adapter.MACAddress
                InterfaceIndex  = $Adapter.DeviceID
                SpeedGbps       = if ($Adapter.Speed) {
                    [math]::Round($Adapter.Speed / 1GB, 2)
                }
                else {
                    $null
                }
                PhysicalAdapter = $Adapter.PhysicalAdapter
            }
        }

        $AdapterInfo |
            Sort-Object @{Expression='PhysicalAdapter'; Descending=$true}, Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve network adapter information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}