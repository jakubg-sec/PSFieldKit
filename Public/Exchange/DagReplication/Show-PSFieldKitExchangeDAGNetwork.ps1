function Show-PSFieldKitExchangeDAGNetwork {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|               DAG NETWORK INFORMATION            |" -ForegroundColor Cyan
    Write-Host "|                      PSFieldKit                  |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        foreach ($DAG in $DAGs) {
            Write-Host "DAG: $($DAG.Name)" -ForegroundColor Cyan
            Write-Host ""

            if ($DAG.DatabaseAvailabilityGroupNetworks) {
                $DAG.DatabaseAvailabilityGroupNetworks |
                    Select-Object `
                        Name,
                        ReplicationEnabled,
                        Subnets,
                        Description |
                    Format-Table -AutoSize
            }
            else {
                Write-Host "No DAG networks found." -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host "Network configuration:" -ForegroundColor Cyan
            Write-Host ""

            [PSCustomObject]@{
                DAG                  = $DAG.Name
                NetworkCompression   = $DAG.NetworkCompression
                NetworkEncryption    = $DAG.NetworkEncryption
                ManualDagNetworkConfiguration = $DAG.ManualDagNetworkConfiguration
            } | Format-List

            Write-Host ""
            Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
            Write-Host ""
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve DAG network information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}