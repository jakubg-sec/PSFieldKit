function Remove-PSFieldKitSession {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsMultiTarget) {
        Write-Host "`nPSSession is not available for multiple targets." -ForegroundColor Yellow
        return
    }

    if (-not $Context.IsRemote) {
        Write-Host "`nPSSession requires a remote target." -ForegroundColor Yellow
        return
    }

    if ($null -eq $Context.Session) {
        Write-Host "`nNo PSSession exists for $($Context.ComputerName)." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving PSSession from $($Context.ComputerName)..." -ForegroundColor Yellow

        Remove-PSSession `
            -Session $Context.Session `
            -ErrorAction Stop

        $Context.Session = $null

        Write-Host "`nPSSession removed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to remove PSSession from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}