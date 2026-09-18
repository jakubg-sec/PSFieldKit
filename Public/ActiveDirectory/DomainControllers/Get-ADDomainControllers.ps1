function Get-ADDomainControllers {

    try {

        $DomainControllers = Get-ADDomainController `
            -Filter * `
            -ErrorAction Stop

        if (-not $DomainControllers) {

            Write-Host "`nNo domain controllers found." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nDomain Controllers" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $DomainControllers |
            Select-Object `
                Name,
                HostName,
                IPv4Address,
                Site,
                OperatingSystem,
                IsGlobalCatalog,
                IsReadOnly,
                Enabled |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve domain controllers." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}