function Get-NetworkNeighborTable {

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

                $Neighbors = Get-NetNeighbor `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {

                Remove-CimSession $Session
            }
        }
        else {

            $Neighbors = Get-NetNeighbor `
                -ErrorAction Stop
        }

        $Neighbors |
            Select-Object `
                ifIndex,
                InterfaceAlias,
                IPAddress,
                LinkLayerAddress,
                State,
                AddressFamily |
            Sort-Object AddressFamily, InterfaceAlias, IPAddress |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve ARP / Neighbor table from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}