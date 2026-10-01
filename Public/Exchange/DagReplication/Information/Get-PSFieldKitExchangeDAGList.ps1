function Get-PSFieldKitExchangeDAGList {
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
    Write-Host "|                   DAG LIST                   |" -ForegroundColor Cyan
    Write-Host "|                  PSFieldKit                  |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "|  No Database Availability Groups found.      |" -ForegroundColor Yellow
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ("|  {0,-25} {1,-8} {2,-12} |" -f "DAG Name", "Members", "IP Mode") -ForegroundColor DarkCyan
        Write-Host ("|  {0,-25} {1,-8} {2,-12} |" -f "--------", "-------", "-------") -ForegroundColor DarkGray
        Write-Host "|                                              |"

        foreach ($DAG in $DAGs) {
            $MemberCount = @($DAG.Servers).Count

            $IPMode = "Static"

            if ($DAG.DatabaseAvailabilityGroupIPAddresses) {
                $IPAddresses = @($DAG.DatabaseAvailabilityGroupIPAddresses)

                if (
                    $IPAddresses.Count -eq 1 -and
                    $IPAddresses[0].IPAddressToString -eq "255.255.255.255"
                ) {
                    $IPMode = "DHCP"
                }
            }

            Write-Host ("|  {0,-25} {1,-8} {2,-12} |" -f $DAG.Name, $MemberCount, $IPMode)
        }

        Write-Host "|                                              |"
        Write-Host ("|  Total DAGs : {0,-29}|" -f $DAGs.Count)
    }
    catch {
        Write-Host "|                                              |"
        Write-Host "|  Failed to retrieve DAG information.         |" -ForegroundColor Red
        Write-Host "|                                              |"
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Read-Host "`nPress Enter to continue" | Out-Null
}