function Search-ADGroups {

    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Host "`nSearch term cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $SearchTerm = $SearchTerm.Replace("'", "''")

        $Groups = Get-ADGroup `
            -Filter "Name -like '*$SearchTerm*' -or SamAccountName -like '*$SearchTerm*'" `
            -Properties `
                Description,
                GroupScope,
                GroupCategory,
                ManagedBy `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $Groups) {

            Write-Host "`nNo groups found." `
                -ForegroundColor Yellow

            return
        }

        $Groups |
            Select-Object `
                Name,
                SamAccountName,
                GroupScope,
                GroupCategory,
                Description,
                ManagedBy |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to search Active Directory groups." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}