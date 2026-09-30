function Add-PSFieldKitExchangeDAGMember {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
    Write-Host "|                  ADD DAG MEMBER                  |" -ForegroundColor Cyan
    Write-Host "|                    PSFieldKit                    |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop

        if (-not $DAGs) {
            Write-Host "No Database Availability Groups were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAGs:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt @($DAGs).Count; $i++) {
            Write-Host ("[{0}] {1}" -f `
                ($i + 1),
                $DAGs[$i].Name)
        }

        Write-Host ""

        $DAGSelection = Read-Host "Select DAG"

        if (-not $DAGSelection -match '^\d+$') {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $DAGIndex = [int]$DAGSelection - 1

        if ($DAGIndex -lt 0 -or $DAGIndex -ge @($DAGs).Count) {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedDAG = $DAGs[$DAGIndex]

        Write-Host ""
        Write-Host "Selected DAG: $($SelectedDAG.Name)" -ForegroundColor White
        Write-Host ""

        $Servers = Get-ExchangeServer -ErrorAction Stop |
            Where-Object {
                $_.ServerRole -match "Mailbox"
            }

        if (-not $Servers) {
            Write-Host "No Exchange Mailbox servers were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $ExistingMembers = @(
            $SelectedDAG.DatabaseAvailabilityGroupServers
        )

        $AvailableServers = @(
            $Servers |
                Where-Object {
                    $ExistingMembers -notcontains $_.Name
                }
        )

        if ($AvailableServers.Count -eq 0) {
            Write-Host "No available Exchange servers were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available servers:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $AvailableServers.Count; $i++) {
            Write-Host ("[{0}] {1}" -f `
                ($i + 1),
                $AvailableServers[$i].Name)
        }

        Write-Host ""

        $ServerSelection = Read-Host "Select server"

        if (-not $ServerSelection -match '^\d+$') {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $ServerIndex = [int]$ServerSelection - 1

        if ($ServerIndex -lt 0 -or $ServerIndex -ge $AvailableServers.Count) {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $ServerName = $AvailableServers[$ServerIndex].Name

        Write-Host ""
        Write-Host "DAG    : $($SelectedDAG.Name)" -ForegroundColor White
        Write-Host "Server : $ServerName" -ForegroundColor White
        Write-Host ""

        $Confirmation = Read-Host "Type ADD to continue"

        if ($Confirmation -cne "ADD") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if (
            $PSCmdlet.ShouldProcess(
                $ServerName,
                "Add server to DAG $($SelectedDAG.Name)"
            )
        ) {
            Add-DatabaseAvailabilityGroupServer `
                -Identity $SelectedDAG.Name `
                -MailboxServer $ServerName `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host ""
            Write-Host "Server added to DAG successfully." -ForegroundColor Green
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to add DAG member." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}