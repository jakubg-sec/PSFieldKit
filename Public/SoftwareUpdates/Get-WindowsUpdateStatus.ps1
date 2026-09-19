function Get-WindowsUpdateStatus {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        $ServiceNames = @(
            'wuauserv',
            'BITS',
            'UsoSvc',
            'WaaSMedicSvc'
        )

        foreach ($ServiceName in $ServiceNames) {
            $Service = Get-Service `
                -Name $ServiceName `
                -ErrorAction SilentlyContinue

            if ($null -ne $Service) {
                [PSCustomObject]@{
                    Name        = $Service.Name
                    DisplayName = $Service.DisplayName
                    Status      = $Service.Status
                    StartType   = $Service.StartType
                }
            }
        }
    }

    try {
        Write-Host "`nWindows Update Status" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Services = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Services = & $ScriptBlock
                }

                if ($null -eq $Services) {
                    Write-Host "No Windows Update services were found." `
                        -ForegroundColor Yellow
                    continue
                }

                $Services |
                    Select-Object `
                        Name,
                        DisplayName,
                        Status,
                        StartType |
                    Sort-Object Name |
                    Format-Table -AutoSize
            }
            catch {
                Write-Host "Failed to retrieve Windows Update status." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve Windows Update status." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}