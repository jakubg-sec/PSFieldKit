function Search-ADLDAPFilter {
    $LDAPFilter = Read-Host "Enter LDAP filter"

    if ([string]::IsNullOrWhiteSpace($LDAPFilter)) {
        Write-Host "`nLDAP filter cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Domain = Get-ADDomain -ErrorAction Stop

        $SearchBase = Read-Host "Enter search base DN (leave empty for domain root)"

        if ([string]::IsNullOrWhiteSpace($SearchBase)) {
            $SearchBase = $Domain.DistinguishedName
        }
        else {
            Get-ADObject `
                -Identity $SearchBase `
                -ErrorAction Stop |
                Out-Null
        }

        Write-Host "`nSelect search scope"
        Write-Host "[1] Subtree"
        Write-Host "[2] OneLevel"
        Write-Host "[3] Base"

        $ScopeChoice = Read-Host "`nSelect option"

        switch ($ScopeChoice) {
            '1' {
                $SearchScope = 'Subtree'
            }
            '2' {
                $SearchScope = 'OneLevel'
            }
            '3' {
                $SearchScope = 'Base'
            }
            default {
                Write-Host "`nInvalid search scope." -ForegroundColor Red
                return
            }
        }

        Write-Host "`nSearching Active Directory..." -ForegroundColor Yellow

        $Objects = Get-ADObject `
            -LDAPFilter $LDAPFilter `
            -SearchBase $SearchBase `
            -SearchScope $SearchScope `
            -Properties `
                SamAccountName,
                UserPrincipalName,
                DNSHostName,
                ObjectCategory `
            -ResultSetSize 100 `
            -ErrorAction Stop

        if (-not $Objects) {
            Write-Host "`nNo objects found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nLDAP Search Results" -ForegroundColor Cyan
        Write-Host "-------------------" -ForegroundColor DarkCyan
        Write-Host "Filter      : $LDAPFilter"
        Write-Host "Search Base : $SearchBase"
        Write-Host "Scope       : $SearchScope"
        Write-Host ""

        $Results = $Objects |
            Select-Object `
                Name,
                ObjectClass,
                SamAccountName,
                UserPrincipalName,
                DNSHostName,
                ObjectCategory,
                DistinguishedName |
            Sort-Object ObjectClass, Name

        $Results |
            Format-Table `
                Name,
                ObjectClass,
                SamAccountName,
                UserPrincipalName,
                DNSHostName,
                ObjectCategory `
                -Wrap `
                -AutoSize

        Write-Host ""
        Write-Host "Results returned: $(@($Results).Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "`nFailed to execute LDAP search." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}