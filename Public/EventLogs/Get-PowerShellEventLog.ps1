function Get-PowerShellEventLog {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $EventCountInput = Read-Host "Enter number of events to retrieve from each log [50]"
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

    $LogNames = @(
        'Microsoft-Windows-PowerShell/Operational',
        'Windows PowerShell'
    )

    try {
        $Events = @()

        if ($Context.IsMultiTarget) {
            foreach ($Target in $Context.Targets) {
                Write-Host "`nRetrieving PowerShell events from $($Target.ComputerName)..." `
                    -ForegroundColor Yellow

                foreach ($LogName in $LogNames) {
                    try {
                        $TargetEvents = Get-WinEvent `
                            -ComputerName $Target.ComputerName `
                            -LogName $LogName `
                            -MaxEvents $EventCount `
                            -ErrorAction Stop

                        $Events += $TargetEvents
                    }
                    catch {
                        continue
                    }
                }
            }
        }
        elseif ($Context.IsRemote) {
            foreach ($LogName in $LogNames) {
                try {
                    $Events += Get-WinEvent `
                        -ComputerName $Context.ComputerName `
                        -LogName $LogName `
                        -MaxEvents $EventCount `
                        -ErrorAction Stop
                }
                catch {
                    continue
                }
            }
        }
        else {
            foreach ($LogName in $LogNames) {
                try {
                    $Events += Get-WinEvent `
                        -LogName $LogName `
                        -MaxEvents $EventCount `
                        -ErrorAction Stop
                }
                catch {
                    continue
                }
            }
        }

        if ($null -eq $Events -or $Events.Count -eq 0) {
            Write-Host "`nNo PowerShell events found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nPowerShell Events" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor DarkCyan

        $Events |
            Sort-Object TimeCreated -Descending |
            Select-Object `
                @{Name = 'Computer'; Expression = {
                    $_.MachineName
                }},
                @{Name = 'Log'; Expression = {
                    $_.LogName
                }},
                TimeCreated,
                Id,
                LevelDisplayName,
                ProviderName,
                Message |
            Format-Table -Wrap -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve PowerShell events." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}