function Get-NetworkStatistics {

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

                $Statistics = Get-NetAdapterStatistics `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {

                Remove-CimSession $Session
            }
        }
        else {

            $Statistics = Get-NetAdapterStatistics `
                -ErrorAction Stop
        }

        $NetworkStatistics = foreach ($Statistic in $Statistics) {

            [PSCustomObject]@{
                Name              = $Statistic.Name
                ReceivedBytesGB   = [math]::Round(
                    $Statistic.ReceivedBytes / 1GB,
                    2
                )
                SentBytesGB       = [math]::Round(
                    $Statistic.SentBytes / 1GB,
                    2
                )
                ReceivedPackets   = $Statistic.ReceivedPackets
                SentPackets       = $Statistic.SentPackets
                ReceivedErrors    = $Statistic.ReceivedErrors
                SentErrors        = $Statistic.SentErrors
                ReceivedDiscarded = $Statistic.ReceivedDiscarded
                OutboundDiscarded = $Statistic.OutboundDiscarded
            }
        }

        $NetworkStatistics |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve network statistics from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}