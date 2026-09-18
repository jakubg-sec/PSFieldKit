function Rename-PSFKADOrganizationalUnit {

    $Identity = Read-Host "Enter OU name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nOU identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    $Identity = $Identity.Trim()

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        # ---------------------------------------
        # Prevent domain rename
        # ---------------------------------------

        if (
            $Identity -eq $Domain.Name -or
            $Identity -eq $Domain.DNSRoot -or
            $Identity -eq $Domain.DistinguishedName
        ) {

            Write-Host "`n'$Identity' is the domain, not an Organizational Unit." `
                -ForegroundColor Red

            Write-Host "The domain itself cannot be renamed by this function." `
                -ForegroundColor Yellow

            return
        }

        # ---------------------------------------
        # Resolve OU
        # ---------------------------------------

        $OU = $null

        # Try exact DN / identity first
        try {

            $OU = Get-ADOrganizationalUnit `
                -Identity $Identity `
                -Properties ProtectedFromAccidentalDeletion `
                -ErrorAction Stop
        }
        catch {

            # Search OU by name
            $SafeName = $Identity.Replace("'", "''")

            $mtch = @(
                Get-ADOrganizationalUnit `
                    -Filter "Name -eq '$SafeName'" `
                    -Properties ProtectedFromAccidentalDeletion `
                    -ErrorAction Stop
            )

            if ($mtch.Count -eq 0) {

                Write-Host "`nOrganizational Unit '$Identity' not found." `
                    -ForegroundColor Red

                return
            }

            if ($mtch.Count -gt 1) {

                Write-Host "`nMultiple OUs with the name '$Identity' were found:" `
                    -ForegroundColor Yellow

                $mtch |
                    Select-Object Name, DistinguishedName |
                    Format-Table -AutoSize

                Write-Host "`nUse Distinguished Name to select the exact OU." `
                    -ForegroundColor Yellow

                return
            }

            $OU = $mtch[0]
        }

        # ---------------------------------------
        # OU information
        # ---------------------------------------

        Write-Host "`nOU Information" -ForegroundColor Cyan
        Write-Host "--------------"

        Write-Host "Current Name : $($OU.Name)"
        Write-Host "DN           : $($OU.DistinguishedName)"
        Write-Host "Protected    : $($OU.ProtectedFromAccidentalDeletion)"

        # ---------------------------------------
        # New name
        # ---------------------------------------

        $NewName = Read-Host "`nEnter new OU name"

        if ([string]::IsNullOrWhiteSpace($NewName)) {

            Write-Host "`nNew OU name cannot be empty." `
                -ForegroundColor Red

            return
        }

        $NewName = $NewName.Trim()

        if ($NewName -eq $OU.Name) {

            Write-Host "`nNew name is the same as the current name." `
                -ForegroundColor Yellow

            return
        }

        # ---------------------------------------
        # Determine parent
        # ---------------------------------------

        $ParentDN = $OU.DistinguishedName.Substring(
            $OU.DistinguishedName.IndexOf(',') + 1
        )

        # ---------------------------------------
        # Check duplicate name
        # ---------------------------------------

        $SafeNewName = $NewName.Replace("'", "''")

        $ExistingObject = Get-ADObject `
            -SearchBase $ParentDN `
            -SearchScope OneLevel `
            -Filter "Name -eq '$SafeNewName'" `
            -ErrorAction Stop

        if ($ExistingObject) {

            Write-Host "`nAn object named '$NewName' already exists in this location." `
                -ForegroundColor Red

            return
        }

        # ---------------------------------------
        # Summary
        # ---------------------------------------

        Write-Host "`nRename:" -ForegroundColor Cyan

        Write-Host "From : $($OU.Name)"
        Write-Host "To   : $NewName"
        Write-Host "Old DN : $($OU.DistinguishedName)"
        Write-Host "New DN : OU=$NewName,$ParentDN"

        # ---------------------------------------
        # Confirmation
        # ---------------------------------------

        $Confirmation = Read-Host "`nRename this OU? [Y/N]"

        if ($Confirmation -notmatch '^[Yy]$') {

            Write-Host "`nOperation cancelled." `
                -ForegroundColor Yellow

            return
        }

        # ---------------------------------------
        # Rename
        # ---------------------------------------

        Rename-ADObject `
            -Identity $OU.DistinguishedName `
            -NewName $NewName `
            -ErrorAction Stop

        Write-Host "`nOU renamed successfully." `
            -ForegroundColor Green

        Write-Host "New name: $NewName"
        Write-Host "New DN  : OU=$NewName,$ParentDN"
    }

    catch {

        Write-Host "`nFailed to rename Organizational Unit." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}