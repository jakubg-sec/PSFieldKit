function Get-NetworkIPConfiguration {

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

            $Configurations = Get-CimInstance `
                -ClassName Win32_NetworkAdapterConfiguration `
                -ComputerName $Context.ComputerName `
                -Filter "IPEnabled = TRUE" `
                -ErrorAction Stop
        }
        else {

            $Adapters = Get-CimInstance `
                -ClassName Win32_NetworkAdapter `
                -ErrorAction Stop

            $Configurations = Get-CimInstance `
                -ClassName Win32_NetworkAdapterConfiguration `
                -Filter "IPEnabled = TRUE" `
                -ErrorAction Stop
        }

        $IPConfiguration = foreach ($Configuration in $Configurations) {

            $Adapter = $Adapters |
                Where-Object {
                    $_.Index -eq $Configuration.Index
                }

            $IPv4Addresses = @(
                $Configuration.IPAddress |
                Where-Object {
                    $_ -notmatch ':'
                }
            )

            $IPv6Addresses = @(
                $Configuration.IPAddress |
                Where-Object {
                    $_ -match ':'
                }
            )

            $SubnetMasks = @(
                $Configuration.IPSubnet |
                Where-Object {
                    $_ -notmatch ':'
                }
            )

            $Gateways = @(
                $Configuration.DefaultIPGateway
            )

            $DnsServers = @(
                $Configuration.DNSServerSearchOrder
            )

            [PSCustomObject]@{
                Name        = $Adapter.NetConnectionID
                IPv4        = $IPv4Addresses -join ', '
                SubnetMask  = $SubnetMasks -join ', '
                IPv6        = $IPv6Addresses -join ', '
                Gateway     = $Gateways -join ', '
                DNS         = $DnsServers -join ', '
                DHCP        = if ($Configuration.DHCPEnabled) {
                    'Enabled'
                }
                else {
                    'Disabled'
                }
            }
        }

        $IPConfiguration |
            Format-Table -AutoSize -Wrap
    }
    catch {

        Write-Host "`nFailed to retrieve IP configuration from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}