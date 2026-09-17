function Get-RoutingTable {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            try {

                $Routes = Get-NetRoute `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {

                Remove-CimSession $Session
            }
        }
        else {

            $Routes = Get-NetRoute `
                -ErrorAction Stop
        }

        $Routes |
            Select-Object `
                DestinationPrefix,
                NextHop,
                RouteMetric,
                InterfaceIndex,
                InterfaceAlias,
                AddressFamily,
                State |
            Sort-Object AddressFamily, DestinationPrefix |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve routing table from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}