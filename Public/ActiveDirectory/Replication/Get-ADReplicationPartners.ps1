function Get-ADReplicationPartners {

    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nDomain controller name cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        Write-Host "`nActive Directory Replication Partners" `
            -ForegroundColor Cyan

        Write-Host "-------------------------------------" `
            -ForegroundColor DarkCyan

        Write-Host "Domain Controller : $HostName"
        Write-Host "Site              : $($DC.Site)"
        Write-Host ""

        $Partners = Get-ADReplicationPartnerMetadata `
            -Target $HostName `
            -PartnerType Both `
            -Partition * `
            -ErrorAction Stop

        if (-not $Partners) {

            Write-Host "No replication partners found." `
                -ForegroundColor Yellow

            return
        }

        $Results = foreach ($Partner in $Partners) {

            $Status = if (
                $Partner.LastReplicationResult -eq 0 -and
                $Partner.ConsecutiveReplicationFailures -eq 0
            ) {
                'PASS'
            }
            else {
                'FAIL'
            }

            [PSCustomObject]@{
                Partner             = $Partner.Partner
                PartnerType         = $Partner.PartnerType
                Partition           = $Partner.Partition
                LastAttempt         = $Partner.LastReplicationAttempt
                LastSuccess         = $Partner.LastReplicationSuccess
                LastResult          = $Partner.LastReplicationResult
                ConsecutiveFailures = $Partner.ConsecutiveReplicationFailures
                Status              = $Status
            }
        }

        Write-Host "`nReplication Partners" `
            -ForegroundColor Cyan

        Write-Host "--------------------" `
            -ForegroundColor DarkCyan

        $Results |
            Sort-Object PartnerType, Partner, Partition |
            Format-Table `
                Partner,
                PartnerType,
                Partition,
                LastAttempt,
                LastSuccess,
                LastResult,
                ConsecutiveFailures,
                Status `
                -AutoSize

        $Failed = $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }

        Write-Host ""

        if ($Failed) {

            Write-Host "Replication problems detected." `
                -ForegroundColor Red
        }
        else {

            Write-Host "All replication partners are healthy." `
                -ForegroundColor Green
        }
    }
    catch {

        Write-Host "`nFailed to retrieve replication partners." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}