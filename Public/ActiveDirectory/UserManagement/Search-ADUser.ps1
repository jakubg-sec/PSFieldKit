function Search-ADUsers {

    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Host "`nSearch term cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $SearchTerm = $SearchTerm.Replace("'", "''")

        $Users = Get-ADUser `
            -Filter "Name -like '*$SearchTerm*' -or SamAccountName -like '*$SearchTerm*' -or UserPrincipalName -like '*$SearchTerm*'" `
            -Properties UserPrincipalName, Enabled, LastLogonDate `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $Users) {

            Write-Host "`nNo users found." -ForegroundColor Yellow

            return
        }

        $Users |
            Select-Object `
                Name,
                SamAccountName,
                UserPrincipalName,
                Enabled,
                LastLogonDate |
            Sort-Object Name |
            Format-Table -AutoSize
    }

    catch {

        Write-Host "`nFailed to search Active Directory users." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}