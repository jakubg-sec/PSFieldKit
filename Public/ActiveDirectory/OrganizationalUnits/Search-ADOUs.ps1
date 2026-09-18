function Search-ADOUs {

    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Host "`nSearch term cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $SearchTerm = $SearchTerm.Replace("'", "''")

        $OUs = Get-ADOrganizationalUnit `
            -Filter "Name -like '*$SearchTerm*' -or DistinguishedName -like '*$SearchTerm*'" `
            -Properties `
                Description,
                ProtectedFromAccidentalDeletion,
                ManagedBy,
                Created,
                Modified `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $OUs) {

            Write-Host "`nNo Organizational Units found." `
                -ForegroundColor Yellow

            return
        }

        $OUs |
            Select-Object `
                Name,
                DistinguishedName,
                Description,
                ProtectedFromAccidentalDeletion,
                ManagedBy,
                Created,
                Modified |
            Sort-Object Name |
            Format-Table -AutoSize -Wrap
    }
    catch {

        Write-Host "`nFailed to search Active Directory Organizational Units." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}