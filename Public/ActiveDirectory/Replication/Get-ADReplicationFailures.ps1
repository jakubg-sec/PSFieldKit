function Get-ADReplicationFailures {
    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDomain controller name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        Write-Host "`nActive Directory Replication Failures" -ForegroundColor Cyan
        Write-Host "-------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host ""

        $Failures = @(
            Get-ADReplicationFailure `
                -Target $HostName `
                -ErrorAction Stop
        )

        if (-not $Failures) {
            Write-Host "No recent replication failures found." -ForegroundColor Green
            return
        }

        $Partners = @(
            Get-ADReplicationPartnerMetadata `
                -Target $HostName `
                -PartnerType Inbound `
                -Partition * `
                -ErrorAction Stop
        )

        $Results = foreach ($Failure in $Failures) {
            $CurrentPartner = $Partners |
                Where-Object {
                    $_.Partner -eq $Failure.Partner
                } |
                Select-Object -First 1

            $CurrentFailure = $false

            if ($CurrentPartner) {
                if (
                    $CurrentPartner.LastReplicationResult -ne 0 -or
                    $CurrentPartner.ConsecutiveReplicationFailures -gt 0
                ) {
                    $CurrentFailure = $true
                }
            }

            $ErrorMessage = switch ($Failure.LastError) {
                0 {
                    'No error'
                }
                1256 {
                    'The remote system is not available'
                }
                1722 {
                    'The RPC server is unavailable'
                }
                1727 {
                    'The remote procedure call failed and did not execute'
                }
                1753 {
                    'There are no more endpoints available from the endpoint mapper'
                }
                1908 {
                    'Could not find the domain controller for this domain'
                }
                8453 {
                    'Replication access was denied'
                }
                8524 {
                    'The DSA operation is unable to proceed because of a DNS lookup failure'
                }
                default {
                    "Windows error $($Failure.LastError)"
                }
            }

            [PSCustomObject]@{
                Server       = $Failure.Server
                Partner      = $Failure.Partner
                FirstFailure = $Failure.FirstFailureTime
                FailureCount = $Failure.FailureCount
                ErrorCode    = $Failure.LastError
                ErrorMessage = $ErrorMessage
                CurrentState = if ($CurrentFailure) {
                    'FAIL'
                }
                else {
                    'RECENT'
                }
            }
        }

        Write-Host "`nReplication Failures" -ForegroundColor Red
        Write-Host "--------------------" -ForegroundColor DarkRed

        $Results |
            Sort-Object FirstFailure |
            Format-Table `
                Server,
                Partner,
                FirstFailure,
                FailureCount,
                ErrorCode,
                ErrorMessage,
                CurrentState `
                -Wrap `
                -AutoSize

        $CurrentFailures = @(
            $Results |
            Where-Object {
                $_.CurrentState -eq 'FAIL'
            }
        )

        $RecentFailures = @(
            $Results |
            Where-Object {
                $_.CurrentState -eq 'RECENT'
            }
        )

        Write-Host ""

        if ($CurrentFailures) {
            Write-Host "Current replication failures detected." -ForegroundColor Red
        }
        elseif ($RecentFailures) {
            Write-Host "Recent replication failures found, but no current replication failure was detected." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nFailed to retrieve replication failures." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}