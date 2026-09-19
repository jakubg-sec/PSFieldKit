function Get-UpdateHistory {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        param(
            [int]$Count
        )

        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

        $TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()

        if ($TotalHistoryCount -eq 0) {
            return @()
        }

        $QueryCount = [math]::Min(
            $Count,
            $TotalHistoryCount
        )

        $History = $UpdateSearcher.QueryHistory(
            0,
            $QueryCount
        )

        foreach ($Entry in $History) {
            $KB = ''

            if ($Entry.Title -match '\bKB\d+\b') {
                $KB = $Matches[0]
            }

            $HResult = $Entry.HResult

            if ($HResult -is [int]) {
                $HResult = ('0x{0:X8}' -f ([uint32]$HResult))
            }

            [PSCustomObject]@{
                Date            = $Entry.Date
                KB              = $KB
                Title           = $Entry.Title
                Operation       = $Entry.Operation
                ResultCode      = $Entry.ResultCode
                HResult         = $HResult
                ClientApplication = $Entry.ClientApplicationID
            }
        }
    }

    try {
        Write-Host "`nUpdate History" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $HistoryCount = 50

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $History = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ArgumentList $HistoryCount `
                        -ErrorAction Stop
                }
                else {
                    $History = & $ScriptBlock $HistoryCount
                }

                $History = @($History)

                if ($History.Count -eq 0) {
                    Write-Host "No Windows Update history was found." `
                        -ForegroundColor Yellow
                    continue
                }

                Write-Host "Showing latest $($History.Count) update history entries." `
                    -ForegroundColor Cyan

                $History |
                    Select-Object `
                        Date,
                        KB,
                        Operation,
                        ResultCode,
                        HResult,
                        Title |
                    Format-Table -AutoSize -Wrap
            }
            catch {
                Write-Host "Failed to retrieve update history." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve Windows Update history." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}