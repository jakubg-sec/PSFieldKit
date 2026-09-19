function Invoke-PSFieldKitScript {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptPath = Read-Host "Enter script path"

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        Write-Host "`nScript path cannot be empty." -ForegroundColor Red
        return
    }

    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Host "`nScript file was not found: $ScriptPath" -ForegroundColor Red
        return
    }

    $ScriptPath = (Resolve-Path -Path $ScriptPath).Path

    if ([System.IO.Path]::GetExtension($ScriptPath) -ne '.ps1') {
        Write-Host "`nThe specified file is not a PowerShell script." -ForegroundColor Red
        return
    }

    try {
        Write-Host "`nRemote Script Execution" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan
        Write-Host "Script: $ScriptPath" -ForegroundColor DarkGray

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                $Result = Invoke-Command `
                    -ComputerName $Target.ComputerName `
                    -FilePath $ScriptPath `
                    -ErrorAction Stop

                if ($null -ne $Result) {
                    $Result | Out-Host
                }

                Write-Host "`nScript completed successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Script execution failed." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to execute remote script." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}