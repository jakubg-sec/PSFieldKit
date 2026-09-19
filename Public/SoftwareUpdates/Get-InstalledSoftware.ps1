function Get-InstalledSoftware {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        $Paths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        foreach ($Path in $Paths) {
            Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.DisplayName)
                } |
                Select-Object `
                    DisplayName,
                    DisplayVersion,
                    Publisher,
                    InstallDate
        }
    }

    try {
        Write-Host "`nInstalled Software" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Software = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Software = & $ScriptBlock
                }

                if ($null -eq $Software) {
                    Write-Host "No installed software was found." -ForegroundColor Yellow
                    continue
                }

                $Software |
                    Sort-Object DisplayName |
                    Format-Table `
                        DisplayName,
                        DisplayVersion,
                        Publisher,
                        InstallDate `
                    -AutoSize
            }
            catch {
                Write-Host "Failed to retrieve installed software." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve installed software." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}