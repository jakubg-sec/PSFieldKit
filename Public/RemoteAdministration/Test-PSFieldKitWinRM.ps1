function Test-PSFieldKitWinRM {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {
        Write-Host "`nWinRM Connectivity Test" -ForegroundColor Cyan
        Write-Host "-----------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                $Result = Test-WSMan `
                    -ComputerName $Target.ComputerName `
                    -ErrorAction Stop

                Write-Host "Status          : Available" -ForegroundColor Green
                Write-Host "Protocol        : $($Result.ProtocolVersion)"
                Write-Host "Product Vendor  : $($Result.ProductVendor)"
                Write-Host "Product Version : $($Result.ProductVersion)"
            }
            catch {
                Write-Host "Status          : Unavailable" -ForegroundColor Red
                Write-Host "Error           : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to test WinRM connectivity." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}