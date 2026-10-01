function Remove-PSFieldKitExchangeDAG {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
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

    while ($true) {
        Clear-Host

        $ServerName = "Unknown"

        if (
            $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
            -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
        ) {
            $ServerName = [string]$ExchangeContext.ServerName
        }

        if ($ServerName.Length -gt 35) {
            $ServerName = $ServerName.Substring(0, 32) + "..."
        }

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                  REMOVE DAG                  |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        try {
            $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)
        }
        catch {
            Write-Host "Unable to retrieve DAG information." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAGs:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $DAGs.Count; $Index++) {
            $DAG = $DAGs[$Index]
            $Members = @($DAG.Servers)

            Write-Host ("[{0}] {1} ({2} member(s))" -f ($Index + 1), $DAG.Name, $Members.Count)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select DAG"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $DAGs.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Start-Sleep -Seconds 1
            continue
        }

        $SelectedDAG = $DAGs[$SelectedIndex - 1]
        $Members = @($SelectedDAG.Servers)

        Write-Host ""

        if ($Members.Count -gt 0) {
            Write-Host "The selected DAG still has members." -ForegroundColor Red
            Write-Host ""
            Write-Host "DAG: $($SelectedDAG.Name)" -ForegroundColor Yellow
            Write-Host ""

            foreach ($Member in $Members) {
                Write-Host "  - $Member" -ForegroundColor Yellow
            }

            Write-Host ""
            Write-Host "Remove all DAG members before removing the DAG." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              REMOVAL SUMMARY                 |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  DAG Name : {0,-31}|" -f $SelectedDAG.Name)
        Write-Host "|  Members  : 0                                |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        Write-Host "WARNING: This will permanently remove the DAG configuration." -ForegroundColor Red
        Write-Host ""

        $Confirmation = Read-Host "Type REMOVE to remove the DAG"

        if ($Confirmation -cne "REMOVE") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            if ($PSCmdlet.ShouldProcess($SelectedDAG.Name, "Remove Database Availability Group")) {
                Remove-DatabaseAvailabilityGroup -Identity $SelectedDAG.Name -Confirm:$false -ErrorAction Stop

                Write-Host ""
                Write-Host "DAG removed successfully." -ForegroundColor Green
                Write-Host ""
                Write-Host "DAG Name : $($SelectedDAG.Name)"
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to remove DAG." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }
}