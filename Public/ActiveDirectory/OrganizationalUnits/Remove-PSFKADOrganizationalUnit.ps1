function Remove-PSFKADOrganizationalUnit {
    $Identity = Read-Host "Enter OU name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nOU identity cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        $OU = $null

        # Full Distinguished Name
        if ($Identity -match '^(OU|CN)=') {
            $OU = Get-ADOrganizationalUnit `
                -Identity $Identity `
                -Properties `
                    Description,
                    ManagedBy,
                    ProtectedFromAccidentalDeletion,
                    Created,
                    Modified `
                -ErrorAction Stop
        }
        else {
            # Search by OU name
            $SafeName = $Identity.Replace("'", "''")

            $MatchingOUs = @(
                Get-ADOrganizationalUnit `
                    -Filter "Name -eq '$SafeName'" `
                    -SearchBase $Domain.DistinguishedName `
                    -SearchScope Subtree `
                    -Properties `
                        Description,
                        ManagedBy,
                        ProtectedFromAccidentalDeletion,
                        Created,
                        Modified `
                    -ErrorAction Stop
            )

            if ($MatchingOUs.Count -eq 0) {
                Write-Host "`nOU '$Identity' was not found." -ForegroundColor Red
                return
            }

            if ($MatchingOUs.Count -gt 1) {
                Write-Host "`nMultiple OUs with the name '$Identity' were found:" -ForegroundColor Yellow
                Write-Host ""

                $MatchingOUs |
                    Select-Object `
                        Name,
                        DistinguishedName |
                    Format-Table -AutoSize

                Write-Host "`nUse the full Distinguished Name to identify the OU." -ForegroundColor Yellow
                return
            }

            $OU = $MatchingOUs[0]
        }

        Write-Host "`nOrganizational Unit Information" -ForegroundColor Cyan
        Write-Host "------------------------------" -ForegroundColor DarkCyan
        Write-Host "Name        : $($OU.Name)"
        Write-Host "Description : $($OU.Description)"
        Write-Host "ManagedBy   : $($OU.ManagedBy)"
        Write-Host "Protected   : $($OU.ProtectedFromAccidentalDeletion)"
        Write-Host "Created     : $($OU.Created)"
        Write-Host "Modified    : $($OU.Modified)"
        Write-Host "DN          : $($OU.DistinguishedName)"
        Write-Host ""

        if ($OU.ProtectedFromAccidentalDeletion) {
            Write-Host "This OU is protected from accidental deletion." -ForegroundColor Red
            Write-Host "Disable the protection before removing the OU." -ForegroundColor Yellow
            return
        }

        $Children = @(
            Get-ADObject `
                -SearchBase $OU.DistinguishedName `
                -SearchScope OneLevel `
                -Filter * `
                -ErrorAction Stop
        )

        if ($Children.Count -gt 0) {
            Write-Host "`nThe OU contains $($Children.Count) object(s)." -ForegroundColor Red
            Write-Host "Remove or move the child objects before deleting the OU." -ForegroundColor Yellow
            Write-Host ""

            $Children |
                Select-Object `
                    Name,
                    ObjectClass,
                    DistinguishedName |
                Sort-Object ObjectClass, Name |
                Format-Table -AutoSize

            return
        }

        Write-Host "`nWARNING: This operation cannot be undone." -ForegroundColor Red
        Write-Host "OU: $($OU.DistinguishedName)"
        Write-Host ""

        $Confirm = Read-Host "Type DELETE to remove this OU"

        if ($Confirm -cne 'DELETE') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        Remove-ADOrganizationalUnit `
            -Identity $OU.DistinguishedName `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "`nOrganizational Unit removed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to remove organizational unit." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}