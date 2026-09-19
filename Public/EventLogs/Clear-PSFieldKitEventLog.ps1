function Clear-PSFieldKitEventLog {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $LogName = Read-Host "Enter log name [System]"

    if ([string]::IsNullOrWhiteSpace($LogName)) {
        $LogName = 'System'
    }

    try {
        if ($Context.IsMultiTarget) {
            $TargetCount = $Context.Targets.Count

            Write-Host "`nWARNING: You are about to clear '$LogName' on $TargetCount computers." `
                -ForegroundColor Red

            Write-Host "This operation will permanently remove the selected event log." `
                -ForegroundColor Yellow
        }
        else {
            Write-Host "`nWARNING: You are about to clear '$LogName' on $($Context.ComputerName)." `
                -ForegroundColor Red

            Write-Host "This operation will permanently remove the selected event log." `
                -ForegroundColor Yellow
        }

        $Confirmation = Read-Host "`nType CLEAR to continue"

        if ($Confirmation -cne 'CLEAR') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        if ($Context.IsMultiTarget) {
            $Targets = $Context.Targets
        }
        else {
            $Targets = @(
                [PSCustomObject]@{
                    ComputerName = $Context.ComputerName
                    IsRemote     = $Context.IsRemote
                }
            )
        }

        foreach ($Target in $Targets) {
            Write-Host "`nClearing '$LogName' on $($Target.ComputerName)..." `
                -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Output = & wevtutil.exe cl $LogName /r:$($Target.ComputerName) 2>&1
                }
                else {
                    $Output = & wevtutil.exe cl $LogName 2>&1
                }

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Event log cleared successfully." `
                        -ForegroundColor Green
                }
                else {
                    Write-Host "Failed to clear event log." `
                        -ForegroundColor Red

                    if ($Output) {
                        Write-Host $Output -ForegroundColor Yellow
                    }
                }
            }
            catch {
                Write-Host "Failed to clear '$LogName' on $($Target.ComputerName)." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to clear event log." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}