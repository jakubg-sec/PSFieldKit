function Get-EventLogInformation {
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

        $Results = foreach ($Target in $Targets) {
            Write-Host "`nRetrieving information from $($Target.ComputerName)..." `
                -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Log = Get-WinEvent `
                        -ComputerName $Target.ComputerName `
                        -ListLog $LogName `
                        -ErrorAction Stop
                }
                else {
                    $Log = Get-WinEvent `
                        -ListLog $LogName `
                        -ErrorAction Stop
                }

                [PSCustomObject]@{
                    Computer          = $Target.ComputerName
                    LogName           = $Log.LogName
                    Enabled           = $Log.IsEnabled
                    LogMode           = $Log.LogMode
                    RecordCount       = $Log.RecordCount
                    MaximumSizeMB     = [math]::Round(
                        $Log.MaximumSizeInBytes / 1MB,
                        2
                    )
                    OldestRecord      = $Log.OldestRecordNumber
                    LogFilePath       = $Log.LogFilePath
                }
            }
            catch {
                Write-Host "Failed to retrieve information from $($Target.ComputerName)." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }

        $Results = @($Results)

        if ($Results.Count -eq 0) {
            Write-Host "`nNo event log information found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nEvent Log Information" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan

        $Results |
            Sort-Object Computer |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve event log information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}