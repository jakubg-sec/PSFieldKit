function Get-SoftwareDetails {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $SoftwareName = Read-Host "Enter software name"

    if ([string]::IsNullOrWhiteSpace($SoftwareName)) {
        Write-Host "`nSoftware name cannot be empty." -ForegroundColor Red
        return
    }

    $ScriptBlock = {
        param(
            [string]$SoftwareName
        )

        $Paths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        foreach ($Path in $Paths) {
            Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.DisplayName) -and
                    $_.DisplayName -like "*$SoftwareName*"
                } |
                Select-Object `
                    DisplayName,
                    DisplayVersion,
                    Publisher,
                    InstallDate,
                    InstallLocation,
                    EstimatedSize,
                    URLInfoAbout,
                    HelpLink,
                    UninstallString,
                    QuietUninstallString
        }
    }

    try {
        Write-Host "`nSoftware Details" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Software = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ArgumentList $SoftwareName `
                        -ErrorAction Stop
                }
                else {
                    $Software = & $ScriptBlock $SoftwareName
                }

                if ($null -eq $Software) {
                    Write-Host "Software '$SoftwareName' was not found." `
                        -ForegroundColor Yellow

                    continue
                }

                foreach ($Application in $Software) {
                    Write-Host "`nName             : $($Application.DisplayName)"
                    Write-Host "Version          : $($Application.DisplayVersion)"
                    Write-Host "Publisher        : $($Application.Publisher)"
                    Write-Host "Install Date     : $($Application.InstallDate)"
                    Write-Host "Install Location : $($Application.InstallLocation)"

                    if ($null -ne $Application.EstimatedSize) {
                        $SizeMB = [math]::Round(
                            $Application.EstimatedSize / 1024,
                            2
                        )

                        Write-Host "Estimated Size   : $SizeMB MB"
                    }
                    else {
                        Write-Host "Estimated Size   :"
                    }

                    Write-Host "URL              : $($Application.URLInfoAbout)"
                    Write-Host "Help Link        : $($Application.HelpLink)"
                    Write-Host "Uninstall String : $($Application.UninstallString)"
                    Write-Host "Quiet Uninstall  : $($Application.QuietUninstallString)"
                }
            }
            catch {
                Write-Host "Failed to retrieve software details." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve software details." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}