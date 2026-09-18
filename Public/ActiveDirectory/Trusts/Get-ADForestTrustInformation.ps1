function Get-ADForestTrustInformation {
    try {
        $Forest = Get-ADForest -ErrorAction Stop

        $ForestTrusts = Get-ADTrust `
            -Filter * `
            -Properties * `
            -ErrorAction Stop |
            Where-Object {
                $_.ForestTransitive -eq $true
            }

        Write-Host "`nForest Trust Information" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan
        Write-Host "Local Forest : $($Forest.Name)"
        Write-Host ""

        if (-not $ForestTrusts) {
            Write-Host "No forest trusts found." -ForegroundColor Yellow
            return
        }

        Write-Host "Forest Trusts" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkCyan

        $ForestTrusts |
            Select-Object `
                Name,
                Source,
                Target,
                Direction,
                TrustType,
                ForestTransitive,
                SelectiveAuthentication,
                SIDFilteringQuarantined |
            Format-Table -AutoSize

        if (@($ForestTrusts).Count -gt 1) {
            Write-Host ""
            $Target = Read-Host "Enter trusted forest name for detailed information"

            if ([string]::IsNullOrWhiteSpace($Target)) {
                return
            }

            $Trust = $ForestTrusts |
                Where-Object {
                    $_.Target -eq $Target -or
                    $_.Name -eq $Target
                } |
                Select-Object -First 1

            if (-not $Trust) {
                Write-Host "`nForest trust not found." -ForegroundColor Red
                return
            }

            $QueryForest = $Trust.Target
        }
        else {
            $QueryForest = $ForestTrusts[0].Target
        }

        $NlTest = Get-Command nltest.exe -ErrorAction SilentlyContinue

        if (-not $NlTest) {
            Write-Host "`nnltest.exe was not found." -ForegroundColor Red
            Write-Host "Install Active Directory / RSAT tools and try again." -ForegroundColor Yellow
            return
        }

        Write-Host "`nForest Trust Records" -ForegroundColor Cyan
        Write-Host "--------------------" -ForegroundColor DarkCyan
        Write-Host "Forest : $QueryForest"
        Write-Host ""

        $Output = & $NlTest.Source `
            "/lsaqueryfti:$QueryForest" 2>&1

        if ($Output) {
            $Output | Out-Host
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nFailed to retrieve forest trust information." -ForegroundColor Red
            Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nFailed to retrieve forest trust information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}