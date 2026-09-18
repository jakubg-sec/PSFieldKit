function Search-ADComputers {

    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {

        Write-Host "`nSearch term cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $SearchTerm = $SearchTerm.Replace("'", "''")

        $Computers = Get-ADComputer `
            -Filter "Name -like '*$SearchTerm*' -or SamAccountName -like '*$SearchTerm*' -or DNSHostName -like '*$SearchTerm*'" `
            -Properties DNSHostName, Enabled, OperatingSystem, IPv4Address, LastLogonDate `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $Computers) {

            Write-Host "`nNo computers found." -ForegroundColor Yellow

            return
        }

        $Computers |
            Select-Object `
                Name,
                DNSHostName,
                IPv4Address,
                OperatingSystem,
                Enabled,
                LastLogonDate |
            Sort-Object Name |
            Format-Table -AutoSize
    }

    catch {

        Write-Host "`nFailed to search Active Directory computers." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}