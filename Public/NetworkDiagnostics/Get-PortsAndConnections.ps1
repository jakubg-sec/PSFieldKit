function Get-PortsAndConnections {

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

                $Connections = Get-NetTCPConnection `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {

                Remove-CimSession $Session
            }
        }
        else {

            $Connections = Get-NetTCPConnection `
                -ErrorAction Stop
        }

        Write-Host "`nListening Ports" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        $ListeningPorts = $Connections |
            Where-Object {
                $_.State -eq 'Listen'
            } |
            Select-Object `
                LocalAddress,
                LocalPort,
                OwningProcess,
                State

        $ListeningPorts |
            Sort-Object LocalPort |
            Format-Table -AutoSize

        Write-Host "`nActive Connections" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $ActiveConnections = $Connections |
            Where-Object {
                $_.State -eq 'Established'
            } |
            Select-Object `
                LocalAddress,
                LocalPort,
                RemoteAddress,
                RemotePort,
                State,
                OwningProcess

        $ActiveConnections |
            Sort-Object RemoteAddress, RemotePort |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve ports and connections from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}