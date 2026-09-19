function Get-DefenderStatus {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        if ($Context.IsRemote) {
            $DefenderStatus = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    Get-MpComputerStatus -ErrorAction Stop
                } `
                -ErrorAction Stop
        }
        else {
            $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
        }

        if ($null -eq $DefenderStatus) {
            Write-Host "`nNo Microsoft Defender status information found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nMicrosoft Defender" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $DefenderStatus |
            Select-Object `
                AMServiceEnabled,
                AntivirusEnabled,
                AntispywareEnabled,
                BehaviorMonitorEnabled,
                RealTimeProtectionEnabled,
                IoavProtectionEnabled,
                NISEnabled,
                OnAccessProtectionEnabled,
                AntivirusSignatureLastUpdated,
                AntivirusSignatureVersion,
                AntispywareSignatureLastUpdated,
                AMProductVersion,
                QuickScanAge,
                FullScanAge |
            Format-List
    }
    catch {
        Write-Host "`nFailed to retrieve Microsoft Defender status from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}