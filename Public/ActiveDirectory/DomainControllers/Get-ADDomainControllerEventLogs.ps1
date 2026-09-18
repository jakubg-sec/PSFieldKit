function Get-ADDomainControllerEventLogs {

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

        $Days = Read-Host "Enter number of days to check (default: 1)"

        if ([string]::IsNullOrWhiteSpace($Days)) {
            $Days = 1
        }
        elseif (-not [int]::TryParse($Days, [ref]$Days) -or $Days -lt 1) {

            Write-Host "`nInvalid number of days." `
                -ForegroundColor Red

            return
        }

        $StartTime = (Get-Date).AddDays(-$Days)

        $Logs = @(
            'Directory Service'
            'DFS Replication'
            'DNS Server'
            'System'
        )

        Write-Host "`nDomain Controller Ev Logs" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan
        Write-Host "DC       : $HostName"
        Write-Host "From     : $StartTime"
        Write-Host "Severity : Critical / Error / Warning"
        Write-Host ""

        foreach ($LogName in $Logs) {

            Write-Host "`n$LogName" -ForegroundColor Cyan
            Write-Host ('-' * $LogName.Length) -ForegroundColor DarkCyan

            try {

                $Evs = Get-WinEv `
                    -ComputerName $HostName `
                    -FilterHashtable @{
                        LogName   = $LogName
                        Level     = 1, 2, 3
                        StartTime = $StartTime
                    } `
                    -ErrorAction Stop |
                    Select-Object -First 50

                if (-not $Evs) {

                    Write-Host "No warnings or errors found." `
                        -ForegroundColor Green

                    continue
                }

                $EvInfo = foreach ($Ev in $Evs) {

                    $Level = switch ($Ev.Level) {
                        1 { 'Critical' }
                        2 { 'Error' }
                        3 { 'Warning' }
                        default { 'Unknown' }
                    }

                    [PSCustomObject]@{
                        TimeCreated = $Ev.TimeCreated
                        Level       = $Level
                        Id          = $Ev.Id
                        Provider    = $Ev.ProviderName
                        Message     = if ($Ev.Message) {
                            ($Ev.Message -replace '\r?\n', ' ')
                        }
                        else {
                            ''
                        }
                    }
                }

                $EvInfo |
                    Sort-Object TimeCreated -Descending |
                    Format-Table -Wrap -AutoSize
            }
            catch {

                Write-Host "Unable to read log '$LogName'." `
                    -ForegroundColor Yellow

                Write-Host $_.Exception.Message `
                    -ForegroundColor DarkYellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to retrieve domain controller Ev logs." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}