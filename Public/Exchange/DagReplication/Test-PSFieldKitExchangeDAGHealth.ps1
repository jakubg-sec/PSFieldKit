function Test-PSFieldKitExchangeDAGHealth {
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
    Write-Host "|                  DAG HEALTH CHECK                |" -ForegroundColor Cyan
    Write-Host "|                     PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $DatabaseCopies = @(
            Get-MailboxDatabaseCopyStatus -ErrorAction Stop
        )

        foreach ($DAG in $DAGs) {

            Write-Host "DAG: $($DAG.Name)" -ForegroundColor Cyan
            Write-Host ""

            # DAG Members
            $Members = @(
                $DAG.DatabaseAvailabilityGroupServers
            )

            Write-Host "DAG Members: $($Members.Count)" -ForegroundColor White

            foreach ($Member in $Members) {
                Write-Host "  [OK] $Member" -ForegroundColor Green
            }

            Write-Host ""

            # Database Copies
            $DAGCopies = @(
                $DatabaseCopies |
                    Where-Object {
                        $Members -contains $_.MailboxServer
                    }
            )

            if ($DAGCopies.Count -eq 0) {
                Write-Host "No database copies found for this DAG." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            Write-Host "Database Copies:" -ForegroundColor Cyan
            Write-Host ""

            foreach ($Copy in $DAGCopies) {

                $StatusOK = $Copy.Status -in @(
                    "Mounted",
                    "Healthy"
                )

                $QueueOK = (
                    [int]$Copy.CopyQueueLength -eq 0 -and
                    [int]$Copy.ReplayQueueLength -eq 0
                )

                if ($StatusOK -and $QueueOK) {
                    Write-Host (
                        "[OK]   {0}\{1} - {2} - CopyQ: {3} - ReplayQ: {4}" -f `
                        $Copy.Name,
                        $Copy.MailboxServer,
                        $Copy.Status,
                        $Copy.CopyQueueLength,
                        $Copy.ReplayQueueLength
                    ) -ForegroundColor Green
                }
                elseif ($StatusOK) {
                    Write-Host (
                        "[WARN] {0}\{1} - {2} - CopyQ: {3} - ReplayQ: {4}" -f `
                        $Copy.Name,
                        $Copy.MailboxServer,
                        $Copy.Status,
                        $Copy.CopyQueueLength,
                        $Copy.ReplayQueueLength
                    ) -ForegroundColor Yellow
                }
                else {
                    Write-Host (
                        "[FAIL] {0}\{1} - {2} - CopyQ: {3} - ReplayQ: {4}" -f `
                        $Copy.Name,
                        $Copy.MailboxServer,
                        $Copy.Status,
                        $Copy.CopyQueueLength,
                        $Copy.ReplayQueueLength
                    ) -ForegroundColor Red
                }
            }

            Write-Host ""

            # Summary
            $FailedCopies = @(
                $DAGCopies |
                    Where-Object {
                        $_.Status -notin @("Mounted", "Healthy")
                    }
            )

            $QueueProblems = @(
                $DAGCopies |
                    Where-Object {
                        [int]$_.CopyQueueLength -gt 0 -or
                        [int]$_.ReplayQueueLength -gt 0
                    }
            )

            if ($FailedCopies.Count -eq 0 -and $QueueProblems.Count -eq 0) {
                Write-Host "DAG Health: HEALTHY" -ForegroundColor Green
            }
            elseif ($FailedCopies.Count -eq 0) {
                Write-Host "DAG Health: WARNING" -ForegroundColor Yellow
            }
            else {
                Write-Host "DAG Health: CRITICAL" -ForegroundColor Red
            }

            Write-Host ""
            Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
            Write-Host ""
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to perform DAG health check." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}