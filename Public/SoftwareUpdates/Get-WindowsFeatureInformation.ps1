function Get-WindowsFeatureInformation {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        if ($null -ne (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)) {
            Get-WindowsFeature |
                Select-Object `
                    Name,
                    DisplayName,
                    InstallState
        }
        elseif ($null -ne (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue)) {
            Get-WindowsOptionalFeature `
                -Online `
                -ErrorAction Stop |
                Select-Object `
                    FeatureName,
                    State
        }
        else {
            throw "No supported Windows feature management cmdlet was found."
        }
    }

    try {
        Write-Host "`nWindows Features" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Features = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Features = & $ScriptBlock
                }

                if ($null -eq $Features) {
                    Write-Host "No Windows features were found." -ForegroundColor Yellow
                    continue
                }

                if ($null -ne $Features[0].InstallState) {
                    $Features |
                        Sort-Object DisplayName |
                        Format-Table `
                            Name,
                            DisplayName,
                            InstallState `
                        -AutoSize
                }
                else {
                    $Features |
                        Sort-Object FeatureName |
                        Format-Table `
                            FeatureName,
                            State `
                        -AutoSize
                }
            }
            catch {
                Write-Host "Failed to retrieve Windows features." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve Windows feature information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}