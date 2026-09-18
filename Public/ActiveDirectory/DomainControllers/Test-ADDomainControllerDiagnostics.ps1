function Test-ADDomainControllerDiagnostics {

    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDomain controller name cannot be empty." -ForegroundColor Red
        return
    }

    try {

        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        Write-Host "`nDomain Controller Diagnostics" -ForegroundColor Cyan
        Write-Host "-----------------------------" -ForegroundColor DarkCyan
        Write-Host "DC: $HostName"
        Write-Host ""

        $Tests = @(
            'Advertising'
            'Services'
            'Replications'
            'SysVolCheck'
            'NetLogons'
        )

        $Results = foreach ($Test in $Tests) {

            Write-Host "Running $Test..." -ForegroundColor Yellow

            $Output = & dcdiag.exe `
                "/s:$HostName" `
                "/test:$Test" `
                /q 2>&1

            $Passed = (
                $LASTEXITCODE -eq 0 -and
                [string]::IsNullOrWhiteSpace(($Output | Out-String).Trim())
            )

            [PSCustomObject]@{
                Test    = $Test
                Status  = if ($Passed) { 'PASS' } else { 'FAIL' }
                Details = if ($Passed) {
                    'No errors reported'
                }
                else {
                    ($Output | Out-String).Trim()
                }
            }
        }

        Write-Host "`nDiagnostic Summary" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $Results |
            Select-Object Test, Status |
            Format-Table -AutoSize

        $Failed = $Results | Where-Object Status -eq 'FAIL'

        if ($Failed) {

            Write-Host "`nFailed Tests" -ForegroundColor Red
            Write-Host "------------" -ForegroundColor DarkRed

            foreach ($Result in $Failed) {

                Write-Host "`n[$($Result.Test)]" -ForegroundColor Red
                Write-Host $Result.Details -ForegroundColor Yellow
            }
        }
        else {

            Write-Host "`nAll domain controller diagnostic tests passed." `
                -ForegroundColor Green
        }
    }
    catch {

        Write-Host "`nFailed to run domain controller diagnostics." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}