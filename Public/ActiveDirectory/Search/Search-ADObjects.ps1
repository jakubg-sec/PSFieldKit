function Search-ADObjects {
    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Host "`nSearch term cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $SearchTerm = $SearchTerm.Replace("'", "''")

        $Objects = Get-ADObject `
            -Filter "Name -like '*$SearchTerm*' -or SamAccountName -like '*$SearchTerm*' -or UserPrincipalName -like '*$SearchTerm*' -or DNSHostName -like '*$SearchTerm*'" `
            -Properties `
                SamAccountName,
                UserPrincipalName,
                DNSHostName,
                ObjectCategory `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $Objects) {
            Write-Host "`nNo Active Directory objects found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nActive Directory Search Results" -ForegroundColor Cyan
        Write-Host "-------------------------------" -ForegroundColor DarkCyan

        $Objects |
            Select-Object `
                Name,
                ObjectClass,
                SamAccountName,
                UserPrincipalName,
                DNSHostName,
                ObjectCategory,
                DistinguishedName |
            Sort-Object ObjectClass, Name |
            Format-Table `
                Name,
                ObjectClass,
                SamAccountName,
                UserPrincipalName,
                DNSHostName `
                -Wrap `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to search Active Directory objects." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}