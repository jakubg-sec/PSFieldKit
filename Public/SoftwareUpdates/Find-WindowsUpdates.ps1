function Find-WindowsUpdates {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        $AutomaticUpdates = New-Object -ComObject Microsoft.Update.AutoUpdate

        try {
            [void]$AutomaticUpdates.DetectNow()

            [PSCustomObject]@{
                Status = 'Started'
            }
        }
        finally {
            if ($null -ne $AutomaticUpdates) {
                [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject(
                    $AutomaticUpdates
                ) | Out-Null
            }
        }
    }

    try {
        Write-Host "`nCheck for Windows Updates" -ForegroundColor Cyan
        Write-Host "-------------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Result = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Result = & $ScriptBlock
                }

                if ($Result.Status -eq 'Started') {
                    Write-Host "Update detection started successfully." `
                        -ForegroundColor Green

                    Write-Host "Use [5] Available Updates to view available updates after the scan completes." `
                        -ForegroundColor DarkGray
                }
            }
            catch {
                Write-Host "Failed to start Windows Update detection." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to check for Windows Updates." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}