function Get-PSFieldKitExchangeDAGMembers {
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
    Write-Host "|                 DAG MEMBERS                  |" -ForegroundColor Cyan
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

            $Members = @($DAG.Servers)

            if ($Members.Count -eq 0) {
                Write-Host "  No members found." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            Write-Host ("  {0,-30} {1,-15}" -f "Server", "Status") -ForegroundColor DarkCyan
            Write-Host ("  {0,-30} {1,-15}" -f "------", "------") -ForegroundColor DarkGray

            foreach ($Member in $Members) {
                $ServerName = [string]$Member.Name

                if ([string]::IsNullOrWhiteSpace($ServerName)) {
                    $ServerName = [string]$Member
                }

                if ($Member.OperationalServer -eq $true) {
                    $Status = "Healthy"
                    $Color = "Green"
                }
                else {
                    $Status = "Unhealthy"
                    $Color = "Red"
                }

                Write-Host ("  {0,-30} {1,-15}" -f $ServerName, $Status) -ForegroundColor $Color
            }

            Write-Host ""
        }
    }
    catch {
        Write-Host "Failed to retrieve DAG members." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}