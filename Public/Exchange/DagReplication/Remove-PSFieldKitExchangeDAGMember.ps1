function Remove-PSFieldKitExchangeDAGMember {
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
    Write-Host "|                 REMOVE DAG MEMBER                |" -ForegroundColor Cyan
    Write-Host "|                    PSFieldKit                    |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAGs:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $DAGs.Count; $i++) {
            Write-Host ("[{0}] {1}" -f ($i + 1), $DAGs[$i].Name)
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

        if ($DAGIndex -lt 0 -or $DAGIndex -ge $DAGs.Count) {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedDAG = $DAGs[$DAGIndex]

        $Members = @(
            $SelectedDAG.DatabaseAvailabilityGroupServers
        )

        if ($Members.Count -eq 0) {
            Write-Host ""
            Write-Host "No DAG members were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""
        Write-Host "DAG: $($SelectedDAG.Name)" -ForegroundColor White
        Write-Host ""
        Write-Host "Members:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $Members.Count; $i++) {
            Write-Host ("[{0}] {1}" -f ($i + 1), $Members[$i])
        }

        Write-Host ""

        $MemberSelection = Read-Host "Select member to remove"

        if (-not $MemberSelection -match '^\d+$') {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $MemberIndex = [int]$MemberSelection - 1

        if ($MemberIndex -lt 0 -or $MemberIndex -ge $Members.Count) {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $ServerName = $Members[$MemberIndex]

        Write-Host ""
        Write-Host "DAG    : $($SelectedDAG.Name)" -ForegroundColor White
        Write-Host "Server : $ServerName" -ForegroundColor White
        Write-Host ""

        Write-Host "WARNING: Removing a DAG member is a destructive operation." -ForegroundColor Yellow
        Write-Host ""

        $Confirmation = Read-Host "Type REMOVE to continue"

        if ($Confirmation -cne "REMOVE") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if (
            $PSCmdlet.ShouldProcess(
                $ServerName,
                "Remove server from DAG $($SelectedDAG.Name)"
            )
        ) {
            Remove-DatabaseAvailabilityGroupServer `
                -Identity $SelectedDAG.Name `
                -MailboxServer $ServerName `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host ""
            Write-Host "DAG member removed successfully." -ForegroundColor Green
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to remove DAG member." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}