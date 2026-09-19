function Restart-PSFieldKitComputer {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if (-not $Context.IsRemote) {
        Write-Host "`nRemote computer power management requires a remote target." `
            -ForegroundColor Yellow
        return
    }

    if ($Context.Targets.Count -eq 0) {
        Write-Host "`nNo remote targets were found." -ForegroundColor Yellow
        return
    }

    Write-Host "`nRemote Reboot / Shutdown" -ForegroundColor Cyan
    Write-Host "-----------------------" -ForegroundColor DarkCyan

    if ($Context.IsMultiTarget) {
        Write-Host "Targets: $($Context.Targets.Count)"
    }
    else {
        Write-Host "Target : $($Context.ComputerName)"
    }

    Write-Host "`nSelect operation:" -ForegroundColor Cyan
    Write-Host "[1] Restart computer"
    Write-Host "[2] Shutdown computer"
    Write-Host "[0] Cancel"

    $Choice = Read-Host "`nSelect option"

    switch ($Choice) {
        '1' {
            $Action = 'Restart'
        }

        '2' {
            $Action = 'Shutdown'
        }

        '0' {
            return
        }

        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            return
        }
    }

    Write-Host

    foreach ($Target in $Context.Targets) {
        Write-Host " - $($Target.ComputerName)" -ForegroundColor Yellow
    }

    Write-Host

    if ($Context.IsMultiTarget) {
        $Confirmation = Read-Host "Type YES to $Action all listed computers"
    }
    else {
        $Confirmation = Read-Host "Type YES to $Action $($Context.ComputerName)"
    }

    if ($Confirmation -ne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    foreach ($Target in $Context.Targets) {
        try {
            if ($Action -eq 'Restart') {
                Write-Host "`nRestarting $($Target.ComputerName)..." `
                    -ForegroundColor Yellow

                Restart-Computer `
                    -ComputerName $Target.ComputerName `
                    -Force `
                    -Confirm:$false `
                    -ErrorAction Stop
            }
            else {
                Write-Host "`nShutting down $($Target.ComputerName)..." `
                    -ForegroundColor Yellow

                Stop-Computer `
                    -ComputerName $Target.ComputerName `
                    -Force `
                    -Confirm:$false `
                    -ErrorAction Stop
            }

            Write-Host "$Action request sent successfully." `
                -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to $($Action.ToLower()) $($Target.ComputerName)." `
                -ForegroundColor Red

            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
}