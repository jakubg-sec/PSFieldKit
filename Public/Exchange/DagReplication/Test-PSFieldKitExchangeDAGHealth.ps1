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
    Write-Host "|                 DAG HEALTH CHECK                |" -ForegroundColor Cyan
    Write-Host "|                    PSFieldKit                  |" -ForegroundColor Cyan
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

            # -------------------------------------------------
            # DAG MEMBERS
            # -------------------------------------------------

            $Members = @(
                $DAG.DatabaseAvailabilityGroupServers
            )

            Write-Host "DAG MEMBERS" -ForegroundColor DarkCyan
            Write-Host ""

            if ($Members.Count -eq 0) {
                Write-Host "[FAIL] No DAG members found." -ForegroundColor Red
            }
            else {
                foreach ($Member in $Members) {
                    Write-Host "[OK]   $Member" -ForegroundColor Green
                }
            }

            Write-Host ""

            # -------------------------------------------------
            # DATABASE COPIES
            # -------------------------------------------------

            $DAGCopies = @(
                $DatabaseCopies |
                    Where-Object {
                        $Members -contains $_.MailboxServer
                    }
            )

            Write-Host "DATABASE COPIES" -ForegroundColor DarkCyan
            Write-Host ""

            if ($DAGCopies.Count -eq 0) {
                Write-Host "[WARN] No database copies found." -ForegroundColor Yellow
            }
            else {
                foreach ($Copy in $DAGCopies) {

                    $Status = [string]$Copy.Status

                    $StatusOK = $Status -in @(
                        "Mounted",
                        "Healthy"
                    )

                    $CopyQueue = 0
                    $ReplayQueue = 0

                    if ($null -ne $Copy.CopyQueueLength) {
                        $CopyQueue = [int]$Copy.CopyQueueLength
                    }

                    if ($null -ne $Copy.ReplayQueueLength) {
                        $ReplayQueue = [int]$Copy.ReplayQueueLength
                    }

                    $QueueOK = (
                        $CopyQueue -eq 0 -and
                        $ReplayQueue -eq 0
                    )

                    if ($StatusOK -and $QueueOK) {
                        $HealthState = "OK"
                        $Color = "Green"
                    }
                    elseif ($StatusOK) {
                        $HealthState = "WARN"
                        $Color = "Yellow"
                    }
                    else {
                        $HealthState = "FAIL"
                        $Color = "Red"
                    }

                    Write-Host (
                        "[{0}] {1}\{2} - {3} - CopyQ: {4} - ReplayQ: {5}" -f `
                        $HealthState,
                        $Copy.Name,
                        $Copy.MailboxServer,
                        $Status,
                        $CopyQueue,
                        $ReplayQueue
                    ) -ForegroundColor $Color
                }
            }

            Write-Host ""

            # -------------------------------------------------
            # REPLICATION
            # -------------------------------------------------

            Write-Host "REPLICATION" -ForegroundColor DarkCyan
            Write-Host ""

            $FailedCopies = @(
                $DAGCopies |
                    Where-Object {
                        $_.Status -notin @(
                            "Mounted",
                            "Healthy"
                        )
                    }
            )

            $QueueProblems = @(
                $DAGCopies |
                    Where-Object {
                        $CopyQueue = 0
                        $ReplayQueue = 0

                        if ($null -ne $_.CopyQueueLength) {
                            $CopyQueue = [int]$_.CopyQueueLength
                        }

                        if ($null -ne $_.ReplayQueueLength) {
                            $ReplayQueue = [int]$_.ReplayQueueLength
                        }

                        $CopyQueue -gt 0 -or
                        $ReplayQueue -gt 0
                    }
            )

            if ($FailedCopies.Count -eq 0) {
                Write-Host "[OK]   Database copy status" -ForegroundColor Green
            }
            else {
                Write-Host (
                    "[FAIL] {0} database copy/copies have unhealthy status" -f
                    $FailedCopies.Count
                ) -ForegroundColor Red
            }

            if ($QueueProblems.Count -eq 0) {
                Write-Host "[OK]   Replication queues" -ForegroundColor Green
            }
            else {
                Write-Host (
                    "[WARN] {0} database copy/copies have replication queue backlog" -f
                    $QueueProblems.Count
                ) -ForegroundColor Yellow
            }

            Write-Host ""

            # -------------------------------------------------
            # OVERALL HEALTH
            # -------------------------------------------------

            if (
                $Members.Count -gt 0 -and
                $FailedCopies.Count -eq 0 -and
                $QueueProblems.Count -eq 0
            ) {
                Write-Host "DAG HEALTH: HEALTHY" -ForegroundColor Green
            }
            elseif ($FailedCopies.Count -eq 0) {
                Write-Host "DAG HEALTH: WARNING" -ForegroundColor Yellow
            }
            else {
                Write-Host "DAG HEALTH: CRITICAL" -ForegroundColor Red
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