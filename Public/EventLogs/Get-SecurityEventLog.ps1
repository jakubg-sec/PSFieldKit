function Get-SecurityEventLog {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $EventCountInput = Read-Host "Enter number of events to retrieve [50]"
    $EventCount = 0

    if ([string]::IsNullOrWhiteSpace($EventCountInput)) {
        $EventCount = 50
    }
    elseif (-not [int]::TryParse($EventCountInput, [ref]$EventCount)) {
        Write-Host "`nInvalid number of events." -ForegroundColor Red
        return
    }
    elseif ($EventCount -lt 1) {
        Write-Host "`nNumber of events must be greater than 0." -ForegroundColor Red
        return
    }

    try {
        $Events = @()

        if ($Context.IsMultiTarget) {
            foreach ($Target in $Context.Targets) {
                Write-Host "`nRetrieving Security events from $($Target.ComputerName)..." `
                    -ForegroundColor Yellow

                try {
                    $TargetEvents = Get-WinEvent `
                        -ComputerName $Target.ComputerName `
                        -LogName 'Security' `
                        -MaxEvents $EventCount `
                        -ErrorAction Stop

                    $Events += $TargetEvents
                }
                catch {
                    Write-Host "Failed to retrieve events from $($Target.ComputerName)." `
                        -ForegroundColor Red

                    Write-Host $_.Exception.Message -ForegroundColor Yellow
                }
            }
        }
        elseif ($Context.IsRemote) {
            $Events = Get-WinEvent `
                -ComputerName $Context.ComputerName `
                -LogName 'Security' `
                -MaxEvents $EventCount `
                -ErrorAction Stop
        }
        else {
            $Events = Get-WinEvent `
                -LogName 'Security' `
                -MaxEvents $EventCount `
                -ErrorAction Stop
        }

        if ($null -eq $Events -or $Events.Count -eq 0) {
            Write-Host "`nNo Security events found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nSecurity Events" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        $Events |
            Sort-Object TimeCreated -Descending |
            Select-Object `
                @{Name = 'Computer'; Expression = {
                    $_.MachineName
                }},
                TimeCreated,
                Id,
                LevelDisplayName,
                ProviderName,
                Message |
            Format-Table -Wrap -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve Security events." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}