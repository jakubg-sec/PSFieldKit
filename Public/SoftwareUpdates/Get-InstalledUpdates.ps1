function Get-InstalledUpdates {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {
        Write-Host "`nInstalled Updates" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Session = New-CimSession `
                        -ComputerName $Target.ComputerName `
                        -ErrorAction Stop

                    try {
                        $Updates = Get-CimInstance `
                            -ClassName Win32_QuickFixEngineering `
                            -CimSession $Session `
                            -ErrorAction Stop
                    }
                    finally {
                        Remove-CimSession $Session
                    }
                }
                else {
                    $Updates = Get-CimInstance `
                        -ClassName Win32_QuickFixEngineering `
                        -ErrorAction Stop
                }

                if ($null -eq $Updates) {
                    Write-Host "No installed updates were found." -ForegroundColor Yellow
                    continue
                }

                Write-Host "Installed updates: $($Updates.Count)" -ForegroundColor Cyan

                $Updates |
                    Select-Object `
                        HotFixID,
                        Description,
                        InstalledOn,
                        InstalledBy |
                    Sort-Object InstalledOn -Descending |
                    Format-Table -AutoSize
            }
            catch {
                Write-Host "Failed to retrieve installed updates." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve installed updates." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}