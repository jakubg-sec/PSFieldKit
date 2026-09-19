function Search-PSFieldKitEventLog {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $LogName = Read-Host "Enter log name [System]"

    if ([string]::IsNullOrWhiteSpace($LogName)) {
        $LogName = 'System'
    }

    $EventIdInput = Read-Host "Enter Event ID [All]"
    $EventId = $null

    if (-not [string]::IsNullOrWhiteSpace($EventIdInput)) {
        $ParsedEventId = 0

        if (-not [int]::TryParse($EventIdInput, [ref]$ParsedEventId)) {
            Write-Host "`nInvalid Event ID." -ForegroundColor Red
            return
        }

        if ($ParsedEventId -lt 0) {
            Write-Host "`nEvent ID cannot be negative." -ForegroundColor Red
            return
        }

        $EventId = $ParsedEventId
    }

    $LevelInput = Read-Host "Enter level [All/Error/Warning/Information/Critical]"
    $Level = $null

    if (-not [string]::IsNullOrWhiteSpace($LevelInput)) {
        switch ($LevelInput.ToLower()) {
            'critical' {
                $Level = 1
            }

            'error' {
                $Level = 2
            }

            'warning' {
                $Level = 3
            }

            'information' {
                $Level = 4
            }

            'verbose' {
                $Level = 5
            }

            'all' {
                $Level = $null
            }

            default {
                Write-Host "`nInvalid event level." -ForegroundColor Red
                return
            }
        }
    }

    $ProviderName = Read-Host "Enter provider name [All]"

    if ([string]::IsNullOrWhiteSpace($ProviderName)) {
        $ProviderName = $null
    }

    $MessageFilter = Read-Host "Enter message filter [All]"

    if ([string]::IsNullOrWhiteSpace($MessageFilter)) {
        $MessageFilter = $null
    }

    $StartTimeInput = Read-Host "Enter start time [All]"
    $StartTime = $null

    if (-not [string]::IsNullOrWhiteSpace($StartTimeInput)) {
        try {
            $StartTime = [datetime]::Parse($StartTimeInput)
        }
        catch {
            Write-Host "`nInvalid start time." -ForegroundColor Red
            return
        }
    }

    $EndTimeInput = Read-Host "Enter end time [Now]"
    $EndTime = Get-Date

    if (-not [string]::IsNullOrWhiteSpace($EndTimeInput)) {
        try {
            $EndTime = [datetime]::Parse($EndTimeInput)
        }
        catch {
            Write-Host "`nInvalid end time." -ForegroundColor Red
            return
        }
    }

    if ($null -ne $StartTime -and $StartTime -gt $EndTime) {
        Write-Host "`nStart time cannot be later than end time." -ForegroundColor Red
        return
    }

    $EventCountInput = Read-Host "Enter maximum number of events per target [100]"
    $EventCount = 100

    if (-not [string]::IsNullOrWhiteSpace($EventCountInput)) {
        if (-not [int]::TryParse($EventCountInput, [ref]$EventCount)) {
            Write-Host "`nInvalid event count." -ForegroundColor Red
            return
        }

        if ($EventCount -lt 1) {
            Write-Host "`nEvent count must be greater than 0." -ForegroundColor Red
            return
        }
    }

    try {
        if ($Context.IsMultiTarget) {
            $Targets = @($Context.Targets)
        }
        else {
            $Targets = @(
                [PSCustomObject]@{
                    ComputerName = $Context.ComputerName
                    IsRemote     = $Context.IsRemote
                }
            )
        }

        $Results = @()

        foreach ($Target in $Targets) {
            Write-Host "`nSearching events on $($Target.ComputerName)..." `
                -ForegroundColor Yellow

            try {
                $FilterHashtable = @{
                    LogName = $LogName
                }

                if ($null -ne $StartTime) {
                    $FilterHashtable.StartTime = $StartTime
                }

                if ($null -ne $EndTime) {
                    $FilterHashtable.EndTime = $EndTime
                }

                if ($null -ne $EventId) {
                    $FilterHashtable.Id = $EventId
                }

                if ($null -ne $Level) {
                    $FilterHashtable.Level = $Level
                }

                if ($Target.IsRemote) {
                    $TargetEvents = Get-WinEvent `
                        -ComputerName $Target.ComputerName `
                        -FilterHashtable $FilterHashtable `
                        -MaxEvents $EventCount `
                        -ErrorAction Stop
                }
                else {
                    $TargetEvents = Get-WinEvent `
                        -FilterHashtable $FilterHashtable `
                        -MaxEvents $EventCount `
                        -ErrorAction Stop
                }

                if ($null -ne $ProviderName) {
                    $TargetEvents = $TargetEvents |
                        Where-Object {
                            $_.ProviderName -like "*$ProviderName*"
                        }
                }

                if ($null -ne $MessageFilter) {
                    $TargetEvents = $TargetEvents |
                        Where-Object {
                            $_.Message -like "*$MessageFilter*"
                        }
                }

                if ($null -ne $TargetEvents) {
                    $Results += $TargetEvents
                }
            }
            catch {
                Write-Host "Failed to search events on $($Target.ComputerName)." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }

        if ($null -eq $Results -or $Results.Count -eq 0) {
            Write-Host "`nNo matching events found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nEvent Search Results" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        $Results |
            Sort-Object TimeCreated -Descending |
            Select-Object `
                @{Name = 'Computer'; Expression = {
                    $_.MachineName
                }},
                LogName,
                TimeCreated,
                Id,
                LevelDisplayName,
                ProviderName,
                Message |
            Format-Table -Wrap -AutoSize
    }
    catch {
        Write-Host "`nFailed to search event logs." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}