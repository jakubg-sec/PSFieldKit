function Get-PSFieldKitExchangeDAGNetworks {
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

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                 DAG NETWORKS                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        foreach ($DAG in $DAGs) {
            Write-Host "DAG: $($DAG.Name)" -ForegroundColor DarkCyan
            Write-Host ""

            try {
                $Networks = @(Get-DatabaseAvailabilityGroupNetwork -Identity $DAG.Name -ErrorAction Stop)
            }
            catch {
                Write-Host "  Failed to retrieve DAG networks." -ForegroundColor Red
                Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                continue
            }

            if ($Networks.Count -eq 0) {
                Write-Host "  No DAG networks found." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            Write-Host ("  {0,-25} {1,-12} {2,-35}" -f "Network", "Replication", "Subnets") -ForegroundColor DarkCyan
            Write-Host ("  {0,-25} {1,-12} {2,-35}" -f "-------", "-----------", "-------") -ForegroundColor DarkGray

            foreach ($Network in $Networks) {
                $NetworkName = [string]$Network.Name

                if ([string]::IsNullOrWhiteSpace($NetworkName)) {
                    $NetworkName = "Unknown"
                }

                if ($Network.ReplicationEnabled -eq $true) {
                    $Replication = "Enabled"
                }
                else {
                    $Replication = "Disabled"
                }

                $Subnets = @($Network.Subnets)

                if ($Subnets.Count -eq 0) {
                    $SubnetDisplay = "None"
                }
                else {
                    $SubnetDisplay = ($Subnets | ForEach-Object {
                        [string]$_
                    }) -join ", "
                }

                if ($SubnetDisplay.Length -gt 35) {
                    $SubnetDisplay = $SubnetDisplay.Substring(0, 32) + "..."
                }

                Write-Host ("  {0,-25} {1,-12} {2,-35}" -f $NetworkName, $Replication, $SubnetDisplay)
            }

            Write-Host ""
        }
    }
    catch {
        Write-Host "Failed to retrieve DAG network information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}