function Search-ADGPOs {

    $SearchTerm = Read-Host "Enter GPO search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Host "`nSearch term cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $GPOs = Get-GPO `
            -All `
            -ErrorAction Stop |
            Where-Object {
                $_.DisplayName -like "*$SearchTerm*" -or
                $_.Id.ToString() -like "*$SearchTerm*"
            } |
            Select-Object `
                DisplayName,
                Id,
                DomainName,
                GpoStatus,
                Owner,
                ModificationTime |
            Sort-Object DisplayName

        if (-not $GPOs) {

            Write-Host "`nNo GPOs found." `
                -ForegroundColor Yellow

            return
        }

        Write-Host "`nGPO Search Results" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $GPOs |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to search GPOs." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}