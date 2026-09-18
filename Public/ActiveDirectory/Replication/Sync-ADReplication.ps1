function Sync-ADReplication {

    Write-Host "`nSynchronize Active Directory Replication" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkCyan

    Write-Host "`n[1] Synchronize all naming contexts"
    Write-Host "[2] Synchronize specific partition"
    Write-Host "[3] Synchronize specific object"
    Write-Host "[0] Back"

    $Choice = Read-Host "`nSelect option"

    switch ($Choice) {

        '1' {

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

                Write-Host ""
                Write-Host "Domain Controller : $HostName"
                Write-Host "Action            : Synchronize all naming contexts"
                Write-Host ""

                $Confirm = Read-Host "Continue? (Y/N)"

                if ($Confirm -notmatch '^[Yy]$') {

                    Write-Host "`nOperation cancelled." `
                        -ForegroundColor Yellow

                    return
                }

                Write-Host "`nStarting synchronization..." `
                    -ForegroundColor Yellow

                & repadmin.exe `
                    /syncall `
                    $HostName `
                    /A `
                    /e `
                    /d

                if ($LASTEXITCODE -eq 0) {

                    Write-Host "`nReplication synchronization completed successfully." `
                        -ForegroundColor Green
                }
                else {

                    Write-Host "`nReplication synchronization reported errors." `
                        -ForegroundColor Red

                    Write-Host "Exit code: $LASTEXITCODE" `
                        -ForegroundColor Yellow
                }
            }
            catch {

                Write-Host "`nFailed to synchronize replication." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message `
                    -ForegroundColor Yellow
            }
        }

        '2' {

            $Identity = Read-Host "Enter domain controller name"

            if ([string]::IsNullOrWhiteSpace($Identity)) {

                Write-Host "`nDomain controller name cannot be empty." `
                    -ForegroundColor Red

                return
            }

            $Partition = Read-Host "Enter naming context DN"

            if ([string]::IsNullOrWhiteSpace($Partition)) {

                Write-Host "`nNaming context cannot be empty." `
                    -ForegroundColor Red

                return
            }

            try {

                $DC = Get-ADDomainController `
                    -Identity $Identity `
                    -ErrorAction Stop

                $HostName = $DC.HostName

                Write-Host ""
                Write-Host "Domain Controller : $HostName"
                Write-Host "Partition         : $Partition"
                Write-Host ""

                $Confirm = Read-Host "Continue? (Y/N)"

                if ($Confirm -notmatch '^[Yy]$') {

                    Write-Host "`nOperation cancelled." `
                        -ForegroundColor Yellow

                    return
                }

                Write-Host "`nStarting synchronization..." `
                    -ForegroundColor Yellow

                & repadmin.exe `
                    /syncall `
                    $HostName `
                    $Partition `
                    /e `
                    /d

                if ($LASTEXITCODE -eq 0) {

                    Write-Host "`nPartition synchronization completed successfully." `
                        -ForegroundColor Green
                }
                else {

                    Write-Host "`nPartition synchronization reported errors." `
                        -ForegroundColor Red

                    Write-Host "Exit code: $LASTEXITCODE" `
                        -ForegroundColor Yellow
                }
            }
            catch {

                Write-Host "`nFailed to synchronize replication." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message `
                    -ForegroundColor Yellow
            }
        }

        '3' {

            $ObjectIdentity = Read-Host `
                "Enter object identity (DN, GUID or sAMAccountName)"

            if ([string]::IsNullOrWhiteSpace($ObjectIdentity)) {

                Write-Host "`nObject identity cannot be empty." `
                    -ForegroundColor Red

                return
            }

            $SourceDC = Read-Host `
                "Enter source domain controller name"

            if ([string]::IsNullOrWhiteSpace($SourceDC)) {

                Write-Host "`nSource domain controller cannot be empty." `
                    -ForegroundColor Red

                return
            }

            $DestinationDC = Read-Host `
                "Enter destination domain controller name"

            if ([string]::IsNullOrWhiteSpace($DestinationDC)) {

                Write-Host "`nDestination domain controller cannot be empty." `
                    -ForegroundColor Red

                return
            }

            try {

                $Object = Get-ADObject `
                    -Identity $ObjectIdentity `
                    -Server $SourceDC `
                    -ErrorAction Stop

                $Source = Get-ADDomainController `
                    -Identity $SourceDC `
                    -ErrorAction Stop

                $Destination = Get-ADDomainController `
                    -Identity $DestinationDC `
                    -ErrorAction Stop

                Write-Host ""
                Write-Host "Object      : $($Object.DistinguishedName)"
                Write-Host "Source DC   : $($Source.HostName)"
                Write-Host "Target DC   : $($Destination.HostName)"
                Write-Host ""

                $Confirm = Read-Host "Continue? (Y/N)"

                if ($Confirm -notmatch '^[Yy]$') {

                    Write-Host "`nOperation cancelled." `
                        -ForegroundColor Yellow

                    return
                }

                Write-Host "`nStarting object synchronization..." `
                    -ForegroundColor Yellow

                Sync-ADObject `
                    -Object $Object `
                    -Source $Source.HostName `
                    -Destination $Destination.HostName `
                    -ErrorAction Stop

                Write-Host "`nObject synchronization completed successfully." `
                    -ForegroundColor Green
            }
            catch {

                Write-Host "`nFailed to synchronize object." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message `
                    -ForegroundColor Yellow
            }
        }

        '0' {

            return
        }

        default {

            Write-Host "`nInvalid option." `
                -ForegroundColor Red
        }
    }
}