function Get-ADReplicationSummary {
    try {
        $DomainControllers = Get-ADDomainController `
            -Filter * `
            -ErrorAction Stop

        if (-not $DomainControllers) {
            Write-Host "`nNo domain controllers found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nActive Directory Replication Summary" -ForegroundColor Cyan
        Write-Host "------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controllers : $($DomainControllers.Count)"
        Write-Host ""

        $Results = foreach ($DC in $DomainControllers) {
            Write-Host "Checking $($DC.HostName)..." -ForegroundColor Yellow

            try {
                $Partners = @(
                    Get-ADReplicationPartnerMetadata `
                        -Target $DC.HostName `
                        -PartnerType Inbound `
                        -Partition * `
                        -ErrorAction Stop
                )

                $Failures = @(
                    Get-ADReplicationFailure `
                        -Target $DC.HostName `
                        -ErrorAction Stop
                )

                $PartnerCount = $Partners.Count
                $RecentFailureCount = $Failures.Count

                $CurrentFailures = @(
                    $Partners |
                    Where-Object {
                        $_.LastReplicationResult -ne 0 -or
                        $_.ConsecutiveReplicationFailures -gt 0
                    }
                )

                $CurrentFailureCount = $CurrentFailures.Count

                $SuccessfulReplications = @(
                    $Partners |
                    Where-Object {
                        $null -ne $_.LastReplicationSuccess
                    }
                )

                if ($SuccessfulReplications) {
                    $OldestSuccess = (
                        $SuccessfulReplications |
                        Sort-Object LastReplicationSuccess |
                        Select-Object -First 1
                    ).LastReplicationSuccess

                    $LargestDelta = New-TimeSpan `
                        -Start $OldestSuccess `
                        -End (Get-Date)
                }
                else {
                    $OldestSuccess = $null
                    $LargestDelta = $null
                }

                if ($CurrentFailureCount -gt 0) {
                    $Status = 'FAIL'
                }
                elseif ($RecentFailureCount -gt 0) {
                    $Status = 'WARN'
                }
                else {
                    $Status = 'PASS'
                }

                [PSCustomObject]@{
                    DomainController   = $DC.HostName
                    Site               = $DC.Site
                    PartnerCount       = $PartnerCount
                    CurrentFailures    = $CurrentFailureCount
                    RecentFailures     = $RecentFailureCount
                    LargestDelta       = if ($LargestDelta) {
                        '{0}d {1}h {2}m' -f `
                            $LargestDelta.Days,
                            $LargestDelta.Hours,
                            $LargestDelta.Minutes
                    }
                    else {
                        'N/A'
                    }
                    LastSuccess        = $OldestSuccess
                    Status             = $Status
                }
            }
            catch {
                [PSCustomObject]@{
                    DomainController   = $DC.HostName
                    Site               = $DC.Site
                    PartnerCount       = 0
                    CurrentFailures    = 0
                    RecentFailures     = 0
                    LargestDelta       = 'N/A'
                    LastSuccess        = $null
                    Status             = 'ERROR'
                }
            }
        }

        Write-Host "`nReplication Summary" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan

        $Results |
            Sort-Object DomainController |
            Format-Table `
                DomainController,
                Site,
                PartnerCount,
                CurrentFailures,
                RecentFailures,
                LargestDelta,
                LastSuccess,
                Status `
                -AutoSize

        $Failed = @(
            $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }
        )

        $Warnings = @(
            $Results |
            Where-Object {
                $_.Status -eq 'WARN'
            }
        )

        $Errors = @(
            $Results |
            Where-Object {
                $_.Status -eq 'ERROR'
            }
        )

        Write-Host ""

        if ($Errors) {
            Write-Host "Replication summary completed with errors." -ForegroundColor Red
        }
        elseif ($Failed) {
            Write-Host "Current replication problems detected on one or more domain controllers." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "Replication is currently healthy, but recent failures were detected." -ForegroundColor Yellow
        }
        else {
            Write-Host "All domain controllers report healthy inbound replication." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to generate replication summary." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}