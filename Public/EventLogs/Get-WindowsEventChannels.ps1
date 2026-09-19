function Get-WindowsEventChannels {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $Filter = Read-Host "Enter channel filter [Microsoft-Windows-*]"

    if ([string]::IsNullOrWhiteSpace($Filter)) {
        $Filter = 'Microsoft-Windows-*'
    }

    try {
        $Channels = @()

        if ($Context.IsMultiTarget) {
            foreach ($Target in $Context.Targets) {
                Write-Host "`nRetrieving event channels from $($Target.ComputerName)..." `
                    -ForegroundColor Yellow

                try {
                    $TargetChannels = Get-WinEvent `
                        -ComputerName $Target.ComputerName `
                        -ListLog $Filter `
                        -ErrorAction Stop |
                        Select-Object `
                            @{Name = 'Computer'; Expression = {
                                $Target.ComputerName
                            }},
                            LogName,
                            IsEnabled,
                            LogMode,
                            RecordCount,
                            @{Name = 'MaximumSize(MB)'; Expression = {
                                [math]::Round(
                                    $_.MaximumSizeInBytes / 1MB,
                                    2
                                )
                            }},
                            LogFilePath

                    $Channels += $TargetChannels
                }
                catch {
                    Write-Host "Failed to retrieve event channels from $($Target.ComputerName)." `
                        -ForegroundColor Red

                    Write-Host $_.Exception.Message -ForegroundColor Yellow
                }
            }
        }
        elseif ($Context.IsRemote) {
            $Channels = Get-WinEvent `
                -ComputerName $Context.ComputerName `
                -ListLog $Filter `
                -ErrorAction Stop |
                Select-Object `
                    @{Name = 'Computer'; Expression = {
                        $Context.ComputerName
                    }},
                    LogName,
                    IsEnabled,
                    LogMode,
                    RecordCount,
                    @{Name = 'MaximumSize(MB)'; Expression = {
                        [math]::Round(
                            $_.MaximumSizeInBytes / 1MB,
                            2
                        )
                    }},
                    LogFilePath
        }
        else {
            $Channels = Get-WinEvent `
                -ListLog $Filter `
                -ErrorAction Stop |
                Select-Object `
                    @{Name = 'Computer'; Expression = {
                        $env:COMPUTERNAME
                    }},
                    LogName,
                    IsEnabled,
                    LogMode,
                    RecordCount,
                    @{Name = 'MaximumSize(MB)'; Expression = {
                        [math]::Round(
                            $_.MaximumSizeInBytes / 1MB,
                            2
                        )
                    }},
                    LogFilePath
        }

        if ($null -eq $Channels -or $Channels.Count -eq 0) {
            Write-Host "`nNo event channels found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nWindows Event Channels" -ForegroundColor Cyan
        Write-Host "----------------------" -ForegroundColor DarkCyan

        $Channels |
            Sort-Object Computer, LogName |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve Windows event channels." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}